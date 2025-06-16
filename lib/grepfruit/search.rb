require "find"
require "etc"

require_relative "decorator"

Warning[:experimental] = false

module Grepfruit
  class Search
    include Decorator

    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :truncate, :search_hidden, :jobs, :json_output

    def initialize(dir:, regex:, exclude:, truncate:, search_hidden:, jobs:, json_output: false)
      @dir = File.expand_path(dir)
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @truncate = truncate
      @search_hidden = search_hidden
      @jobs = jobs || Etc.nprocessors
      @json_output = json_output
      @start_time = Time.now
    end

    def run
      puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n" unless json_output

      all_lines, total_files_with_matches, total_files = [], 0, 0
      raw_matches = []
      workers = create_workers
      file_enumerator = create_file_enumerator
      active_workers = {}

      workers.each do |worker|
        file_path = get_next_file(file_enumerator)
        next unless file_path

        worker.send([file_path, regex, excluded_lines, dir])
        active_workers[worker] = file_path
        total_files += 1
      end

      while active_workers.any?
        ready_worker, (file_results, has_matches) = Ractor.select(*active_workers.keys)
        active_workers.delete(ready_worker)

        total_files_with_matches += 1 if process_worker_result(file_results, has_matches, all_lines, raw_matches)

        next_file = get_next_file(file_enumerator)
        next unless next_file

        ready_worker.send([next_file, regex, excluded_lines, dir])
        active_workers[ready_worker] = next_file
        total_files += 1
      end

      workers.each(&:close_outgoing)

      if json_output
        display_json_results(raw_matches, total_files, total_files_with_matches)
      else
        display_results(all_lines, total_files, total_files_with_matches)
      end
    end

    private

    def get_next_file(enumerator)
      enumerator.next
    rescue StopIteration
      nil
    end

    def create_workers
      Array.new(jobs) do
        Ractor.new do
          loop do
            file_path, pattern, exc_lines, base_dir = Ractor.receive
            results, has_matches = [], false

            File.foreach(file_path).with_index do |line, line_num|
              next unless line.valid_encoding? && line.match?(pattern)

              relative_path = file_path.delete_prefix("#{base_dir}/")
              next if exc_lines.any? { |exc| "#{relative_path}:#{line_num + 1}".end_with?(exc.join("/")) }

              results << [relative_path, line_num + 1, line]
              has_matches = true
            end

            Ractor.yield([results, has_matches])
          end
        end
      end
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

    def process_worker_result(file_results, has_matches, all_lines, raw_matches)
      if has_matches
        raw_matches.concat(file_results) if json_output

        unless json_output
          colored_lines = file_results.map do |relative_path, line_num, line_content|
            "#{cyan("#{relative_path}:#{line_num}")}: #{processed_line(line_content)}"
          end
          all_lines.concat(colored_lines)
          print red("M")
        end
        true
      else
        print green(".") unless json_output
        false
      end
    end

    def excluded_path?(path)
      excluded?(excluded_paths, relative_path(path)) || (!search_hidden && File.basename(path).start_with?("."))
    end

    def excluded?(list, path)
      list.any? { path.split("/").last(_1.length) == _1 }
    end

    def relative_path(path)
      path.delete_prefix("#{dir}/")
    end
  end
end
