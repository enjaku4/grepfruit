require "pathname"
require "find"

require_relative "decorator"

module Grepfruit
  class Search
    include Decorator

    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :truncate, :search_hidden

    def initialize(dir:, regex:, exclude:, truncate:, search_hidden:)
      @dir = dir
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @truncate = truncate
      @search_hidden = search_hidden
    end

    def run
      lines, files, files_with_matches = [], 0, 0

      puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n"

      Find.find(dir) do |path|
        Find.prune if excluded_path?(path)

        next if not_searchable?(path)

        files += 1
        match = process_file(path, lines)

        if match
          files_with_matches += 1
          print red("M")
        else
          print green(".")
        end
      end

      display_results(lines, files, files_with_matches)
    end

    private

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
