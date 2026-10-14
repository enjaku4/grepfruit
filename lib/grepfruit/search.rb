require "etc"
require_relative "ractor_compat"
require_relative "search_worker"

module Grepfruit
  class Search
    BATCH_SIZE = 32

    attr_reader :path, :regex, :exclusions, :inclusions, :excluded_paths, :excluded_lines, :truncate, :search_hidden, :jobs, :json, :count, :relative_paths

    def initialize(path:, regex:, exclude:, include:, truncate:, search_hidden:, jobs:, json: false, count: false, relative_paths: false)
      @path = File.expand_path(path)
      @regex = regex
      @exclusions = exclude
      @inclusions = include
      line_exclusions, @excluded_paths = exclude.partition { _1.split("/").last.include?(":") }
      @excluded_lines = line_exclusions.map do |exclusion|
        pattern, _, line = exclusion.rpartition(":")
        [pattern, line.to_i]
      end
      @truncate = truncate
      @search_hidden = search_hidden
      @jobs = jobs || Etc.nprocessors
      @json = json
      @count = count
      @relative_paths = relative_paths
    end

    private

    def build_result_hash(results)
      result_hash = {
        search: {
          pattern: regex,
          path:,
          exclusions:,
          inclusions:
        },
        summary: {
          files_checked: results.total_files,
          files_with_matches: results.total_files_with_matches,
          total_matches: results.match_count
        }
      }

      unless count
        result_hash[:matches] = results.raw_matches.map do |file_path, line_num, line_content|
          {
            file: file_path,
            line: line_num,
            content: processed_line(line_content)
          }
        end
      end

      result_hash
    end

    def execute_search
      results = SearchResults.new
      relative_base = File.join(File.directory?(path) ? path : File.dirname(path), "")
      workers_and_ports = Array.new(jobs) { create_persistent_worker(relative_base) }
      idle_workers = workers_and_ports.dup
      active_workers = {}
      assigned_tasks = {}
      dirs, files, matched_files = [], [], []

      enqueue_root(relative_base, dirs, files)

      loop do
        while idle_workers.any? && (task = next_task(dirs, files))
          worker, port = idle_workers.pop
          RactorCompat.send_work(worker, task)
          active_workers[worker] = port
          assigned_tasks[worker] = task
        end

        break if active_workers.empty?

        ready_worker, worker_result = RactorCompat.select_ready(active_workers)
        idle_workers << [ready_worker, active_workers.delete(ready_worker)]
        task, payload = assigned_tasks.delete(ready_worker)

        if task == :list
          subdirs, entries = worker_result
          dirs.concat(subdirs)
          files.concat(entries)
        else
          process_search_results(payload, worker_result, results, matched_files)
        end
      end

      shutdown_workers(workers_and_ports.map(&:first))

      # Workers finish in any order; sorting by path components restores Find.find order, the order a single worker reports
      matched_files.sort_by { |rel_path, _| rel_path.split("/") }.each { |_, file_results| results.add_raw_matches(file_results) }

      results
    end

    def process_search_results(entries, worker_result, results, matched_files)
      entries.zip(worker_result) do |(_, rel_path), file_result|
        next unless file_result

        file_results, match_count = file_result
        has_matches = match_count.positive?
        results.total_files += 1

        if has_matches
          results.add_match_count(match_count)
          results.increment_files_with_matches
          matched_files << [rel_path, file_results]
        end

        emit_file_progress(has_matches)
      end
    end

    def emit_file_progress(_has_matches); end

    def create_persistent_worker(relative_base)
      encoding = path.encoding == Encoding::US_ASCII ? Encoding.find("filesystem") : path.encoding

      RactorCompat.create_worker(regex, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden, count, relative_paths) do |port, *config|
        SearchWorker.run(port, *config)
      end
    end

    def enqueue_root(relative_base, dirs, files)
      files << SearchWorker.file_entry(path, path.delete_prefix(relative_base), File.basename(path), excluded_lines) if File.file?(path) && File.readable?(path)
      dirs << path if File.lstat(path).directory?
    end

    def next_task(dirs, files)
      if files.size >= BATCH_SIZE || (dirs.empty? && files.any?)
        [:search, files.pop([BATCH_SIZE, files.size.fdiv(jobs).ceil].min)]
      elsif dirs.any?
        [:list, dirs.pop]
      end
    end

    def shutdown_workers(workers)
      workers.each { |worker| worker.send(:quit) }
    end

    def processed_line(line)
      stripped = line.strip
      truncate && stripped.length > truncate ? "#{stripped[0...truncate]}..." : stripped
    end
  end
end
