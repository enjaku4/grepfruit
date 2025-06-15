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

      files_to_search = collect_files

      if jobs > 1
        process_files_parallel(files_to_search)
      else
        process_files_sequential(files_to_search)
      end
    end

    private

    def collect_files
      files = []
      Find.find(dir) do |path|
        Find.prune if excluded_path?(path)
        files << path unless not_searchable?(path)
      end
      files
    end

    def process_files_sequential(files_to_search)
      lines, files_with_matches = [], 0

      files_to_search.each do |path|
        match = process_file(path, lines)

        if match
          files_with_matches += 1
          print red("M")
        else
          print green(".")
        end
      end

      display_results(lines, files_to_search.size, files_with_matches)
    end

    def process_files_parallel(files_to_search)
      all_lines = []
      total_files_with_matches = 0
      files_processed = 0

      workers = (1..jobs).map do |worker_id|
        create_file_worker_ractor(worker_id)
      end

      file_queue = files_to_search.dup
      active_workers = {}

      workers.each do |worker|
        next unless file_queue.any?

        file_path = file_queue.shift
        worker.send([file_path, regex, excluded_lines, truncate, dir])
        active_workers[worker] = file_path
      end

      while active_workers.any?
        ready_worker, result = Ractor.select(*active_workers.keys)
        active_workers.delete(ready_worker)

        file_results, has_matches = result
        files_processed += 1

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

        next unless file_queue.any?

        next_file = file_queue.shift
        ready_worker.send([next_file, regex, excluded_lines, truncate, dir])
        active_workers[ready_worker] = next_file
      end

      workers.each(&:close_outgoing)

      display_results(all_lines, files_to_search.size, total_files_with_matches)
    end

    def create_file_worker_ractor(_worker_id)
      Ractor.new do
        loop do
          file_path, pattern, exc_lines, _, base_dir = Ractor.receive

          results = []
          has_matches = false

          File.foreach(file_path).with_index do |line, line_num|
            next unless line.valid_encoding?
            next unless line.match?(pattern)

            relative_path = file_path.delete_prefix("#{base_dir}/")
            next if exc_lines.any? { |exc| "#{relative_path}:#{line_num + 1}".end_with?(exc.join("/")) }

            results << [relative_path, line_num + 1, line]
            has_matches = true
          end

          Ractor.yield([results, has_matches])
        end
      end
    end

    def not_searchable?(path)
      File.directory?(path) || File.symlink?(path)
    end

    def process_file(path, lines)
      lines_size = lines.size

      File.foreach(path).with_index do |line, line_num|
        next if !line.valid_encoding? || !line.match?(regex) || excluded_line?(path, line_num)

        lines << decorated_line(path, line_num, line)
      end

      lines.size > lines_size
    end

    def excluded_path?(path)
      excluded?(excluded_paths, relative_path(path)) || !search_hidden && hidden?(path)
    end

    def excluded_line?(path, line_num)
      excluded?(excluded_lines, relative_path_with_line_num(path, line_num))
    end

    def excluded?(list, path)
      list.any? { path.split("/").last(_1.length) == _1 }
    end

    def hidden?(path)
      File.basename(path).start_with?(".")
    end
  end
end
