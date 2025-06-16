require "pathname"
require "find"
require "etc"

require_relative "decorator"

Warning[:experimental] = false

module Grepfruit
  class Search
    include Decorator

    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :truncate, :search_hidden, :jobs

    def initialize(dir:, regex:, exclude:, truncate:, search_hidden:, jobs:)
      @dir = File.expand_path(dir)
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @truncate = truncate
      @search_hidden = search_hidden
      @jobs = jobs || Etc.nprocessors
    end

    def run
      puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n"

      files = []

      Find.find(dir) do |path|
        Find.prune if excluded_path?(path)
        files << path unless not_searchable?(path)
      end

      process_files(files)
    end

    private

    def process_files(files)
      all_lines, total_files_with_matches = [], 0
      workers = Array.new(jobs) do
        Ractor.new do
          loop do
            file_path, pattern, exc_lines, base_dir = Ractor.receive

            results = []
            has_matches = false

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

      total_files = files.size
      active_workers = {}

      workers.each do |worker|
        break if files.empty?

        file_path = files.shift
        worker.send([file_path, regex, excluded_lines, dir])
        active_workers[worker] = file_path
      end

      while active_workers.any?
        ready_worker, (file_results, has_matches) = Ractor.select(*active_workers.keys)
        active_workers.delete(ready_worker)

        if has_matches
          colored_lines = file_results.map do |relative_path, line_num, line_content|
            "#{cyan("#{relative_path}:#{line_num}")}: #{processed_line(line_content)}"
          end
          all_lines.concat(colored_lines)
          total_files_with_matches += 1
          print red("M")
        else
          print green(".")
        end

        next if files.empty?

        next_file = files.shift
        ready_worker.send([next_file, regex, excluded_lines, dir])
        active_workers[ready_worker] = next_file
      end

      workers.each(&:close_outgoing)

      display_results(all_lines, total_files, total_files_with_matches)
    end

    def not_searchable?(path)
      File.directory?(path) || File.symlink?(path)
    end

    def excluded_path?(path)
      excluded?(excluded_paths, relative_path(path)) || (!search_hidden && File.basename(path).start_with?("."))
    end

    def excluded?(list, path)
      list.any? { path.split("/").last(_1.length) == _1 }
    end
  end
end
