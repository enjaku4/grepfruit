require "find"
require "etc"
require_relative "ractor_compat"

Warning[:experimental] = false

module Grepfruit
  class Search
    attr_reader :path, :regex, :exclusions, :inclusions, :excluded_paths, :excluded_lines, :included_paths, :truncate, :search_hidden, :jobs, :json, :count

    def initialize(path:, regex:, exclude:, include:, truncate:, search_hidden:, jobs:, json: false, count: false)
      @path = File.expand_path(path)
      @regex = regex
      @exclusions = exclude
      @inclusions = include
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @included_paths = include.map { _1.split("/") }
      @truncate = truncate
      @search_hidden = search_hidden
      @jobs = jobs || Etc.nprocessors
      @json = json
      @count = count
    end

    private

    def build_result_hash(results)
      result_hash = {
        search: {
          pattern: regex,
          directory: path,
          exclusions: exclusions,
          inclusions: inclusions
        },
        summary: {
          files_checked: results.total_files,
          files_with_matches: results.total_files_with_matches,
          total_matches: results.match_count
        }
      }

      unless count
        result_hash[:matches] = results.raw_matches.map do |relative_path, line_num, line_content|
          {
            file: relative_path,
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

        results.increment_files_with_matches if process_worker_result(worker_result, results)
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

    def create_persistent_worker
      RactorCompat.create_worker do |port|
        loop do
          work = Ractor.receive
          break if work == :quit

          file_path, pattern, exc_lines, base_path, count = work
          file_results, has_matches, match_count = [], false, 0

          File.foreach(file_path).with_index do |line, line_num|
            next unless line.valid_encoding? && line.match?(pattern)

            relative_path = file_path.delete_prefix("#{base_path}/")
            next if exc_lines.any? { "#{relative_path}:#{line_num + 1}".end_with?(_1.join("/")) }

            file_results << [relative_path, line_num + 1, line] unless count
            has_matches = true
            match_count += 1
          end

          RactorCompat.yield_result(port, [file_results, has_matches, match_count])
        end
      end
    end

    def assign_file_to_worker(worker, port, file_enumerator, active_workers, results)
      file_path = get_next_file(file_enumerator)
      return unless file_path

      RactorCompat.send_work(worker, [file_path, regex, excluded_lines, path, count])
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
      Enumerator.new do |yielder|
        Find.find(path) do |file_path|
          Find.prune if excluded_path?(file_path)

          next unless File.file?(file_path)

          yielder << file_path
        end
      end
    end

    def excluded_path?(file_path)
      rel_path = file_path.delete_prefix("#{path}/")

      (File.file?(file_path) && included_paths.any? && !matches_pattern?(included_paths, rel_path)) ||
        matches_pattern?(excluded_paths, rel_path) ||
        (!search_hidden && File.basename(file_path).start_with?("."))
    end

    def matches_pattern?(pattern_list, path)
      pattern_list.any? do |pattern_parts|
        pattern = pattern_parts.join("/")
        File.fnmatch?(pattern, path, File::FNM_PATHNAME) || File.fnmatch?(pattern, File.basename(path))
      end
    end

    def processed_line(line)
      stripped = line.strip
      truncate && stripped.length > truncate ? "#{stripped[0...truncate]}..." : stripped
    end
  end
end
