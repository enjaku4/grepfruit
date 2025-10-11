require "find"
require "etc"

Warning[:experimental] = false

module Grepfruit
  class Search
    include Decorator

    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :included_paths, :truncate, :search_hidden, :jobs, :json_output

    def initialize(dir:, regex:, exclude:, include:, truncate:, search_hidden:, jobs:, json_output: false)
      @dir = File.expand_path(dir)
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @included_paths = include.map { _1.split("/") }
      @truncate = truncate
      @search_hidden = search_hidden
      @jobs = jobs || Etc.nprocessors
      @json_output = json_output
    end

    def run
      puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n" unless json_output

      display_final_results(execute_search)
    end

    private

    def execute_search
      results = SearchResults.new
      workers = Array.new(jobs) { create_persistent_worker }
      file_enumerator = create_file_enumerator
      active_workers = {}

      workers.each do |worker|
        assign_file_to_worker(worker, file_enumerator, active_workers, results)
      end

      while active_workers.any?
        ready_worker, worker_result = Ractor.select(*active_workers.keys)
        active_workers.delete(ready_worker)

        results.increment_files_with_matches if process_worker_result(worker_result, results)
        assign_file_to_worker(ready_worker, file_enumerator, active_workers, results)
      end

      shutdown_workers(workers)
      results
    end

    def display_final_results(results)
      if json_output
        display_json_results(results.raw_matches, results.total_files, results.total_files_with_matches)
      else
        display_results(results.all_lines, results.total_files, results.total_files_with_matches)
      end
    end

    def create_persistent_worker
      Ractor.new do
        loop do
          work = Ractor.receive
          break if work == :quit

          file_path, pattern, exc_lines, base_dir = work
          file_results, has_matches = [], false

          File.foreach(file_path).with_index do |line, line_num|
            next unless line.valid_encoding? && line.match?(pattern)

            relative_path = file_path.delete_prefix("#{base_dir}/")
            next if exc_lines.any? { "#{relative_path}:#{line_num + 1}".end_with?(_1.join("/")) }

            file_results << [relative_path, line_num + 1, line]
            has_matches = true
          end

          Ractor.yield([file_results, has_matches])
        end
      end
    end

    def assign_file_to_worker(worker, file_enumerator, active_workers, results)
      file_path = get_next_file(file_enumerator)
      return unless file_path

      worker.send([file_path, regex, excluded_lines, dir])
      active_workers[worker] = file_path
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
        Find.find(dir) do |path|
          Find.prune if excluded_path?(path)

          next unless File.file?(path)

          yielder << path
        end
      rescue Errno::ENOENT
        puts "Error: Directory '#{dir}' does not exist."
        exit 1
      end
    end

    def process_worker_result(worker_result, results)
      file_results, has_matches = worker_result

      if has_matches
        results.add_raw_matches(file_results) if json_output

        unless json_output
          colored_lines = file_results.map do |relative_path, line_num, line_content|
            "#{cyan("#{relative_path}:#{line_num}")}: #{processed_line(line_content)}"
          end
          results.add_lines(colored_lines)
          print red("M")
        end
      else
        print green(".") unless json_output
      end

      has_matches
    end

    def excluded_path?(path)
      rel_path = path.delete_prefix("#{dir}/")

      (File.file?(path) && included_paths.any? && !matches_pattern?(included_paths, rel_path)) ||
        matches_pattern?(excluded_paths, rel_path) ||
        (!search_hidden && File.basename(path).start_with?("."))
    end

    def matches_pattern?(pattern_list, path)
      pattern_list.any? do |pattern_parts|
        pattern = pattern_parts.join("/")
        File.fnmatch?(pattern, path, File::FNM_PATHNAME) || File.fnmatch?(pattern, File.basename(path))
      end
    end
  end
end
