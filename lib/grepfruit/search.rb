require "find"
require "etc"
require_relative "ractor_compat"

module Grepfruit
  class Search
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
      workers_and_ports = Array.new(jobs) { create_persistent_worker }
      file_enumerator = create_file_enumerator
      active_workers = {}

      workers_and_ports.each do |worker, port|
        assign_file_to_worker(worker, port, file_enumerator, active_workers, results)
      end

      while active_workers.any?
        ready_worker, worker_result = RactorCompat.select_ready(active_workers)
        port = active_workers.delete(ready_worker)

        has_matches = process_worker_result(worker_result, results)
        results.increment_files_with_matches if has_matches
        emit_file_progress(has_matches)
        assign_file_to_worker(ready_worker, port, file_enumerator, active_workers, results)
      end

      shutdown_workers(workers_and_ports.map(&:first))

      results
    end

    def process_worker_result(worker_result, results)
      file_results, has_matches, match_count = worker_result

      return false unless has_matches

      results.add_match_count(match_count)
      results.add_raw_matches(file_results)

      true
    end

    def emit_file_progress(_has_matches); end

    def create_persistent_worker
      RactorCompat.create_worker do |port|
        loop do
          work = Ractor.receive
          break if work == :quit

          file_path, match_path, pattern, exc_lines, count = work
          file_results, has_matches, match_count = [], false, 0

          begin
            File.foreach(file_path).with_index do |line, line_num|
              next unless line.valid_encoding? && line.match?(pattern)

              next if exc_lines.include?(line_num + 1)

              file_results << [match_path, line_num + 1, line] unless count
              has_matches = true
              match_count += 1
            end
          rescue SystemCallError, EncodingError, Regexp::TimeoutError
            file_results, has_matches, match_count = [], false, 0
          end

          RactorCompat.yield_result(port, [file_results, has_matches, match_count])
        end
      end
    end

    def assign_file_to_worker(worker, port, file_enumerator, active_workers, results)
      file_path, match_path, file_excluded_lines = get_next_file(file_enumerator)
      return unless file_path

      RactorCompat.send_work(worker, [file_path, match_path, regex, file_excluded_lines, count])
      active_workers[worker] = port
      results.total_files += 1
    end

    def get_next_file(enumerator)
      enumerator.next
    rescue StopIteration
      nil
    end

    def shutdown_workers(workers)
      workers.each { |worker| worker.send(:quit) }
    end

    def create_file_enumerator
      relative_base = File.join(File.directory?(path) ? path : File.dirname(path), "")

      Enumerator.new do |yielder|
        Find.find(path) do |file_path|
          is_file = File.file?(file_path)
          rel_path = file_path.delete_prefix(relative_base)
          name = File.basename(file_path)

          Find.prune if file_path != path && excluded_path?(is_file, rel_path, name)

          next unless is_file && File.readable?(file_path)

          file_excluded_lines = excluded_lines.filter_map { |pattern, line| line if matches_pattern?(pattern, rel_path, name) }

          yielder << [file_path, relative_paths ? rel_path : file_path, file_excluded_lines]
        end
      end
    end

    def excluded_path?(is_file, rel_path, name)
      (is_file && inclusions.any? && !matches_any?(inclusions, rel_path, name)) ||
        matches_any?(excluded_paths, rel_path, name) ||
        (!search_hidden && name.start_with?("."))
    end

    def matches_any?(patterns, rel_path, name)
      patterns.any? { matches_pattern?(_1, rel_path, name) }
    end

    def matches_pattern?(pattern, rel_path, name)
      File.fnmatch?(pattern, rel_path, File::FNM_PATHNAME | File::FNM_DOTMATCH) || File.fnmatch?(pattern, name, File::FNM_DOTMATCH)
    end

    def processed_line(line)
      stripped = line.strip
      truncate && stripped.length > truncate ? "#{stripped[0...truncate]}..." : stripped
    end
  end
end
