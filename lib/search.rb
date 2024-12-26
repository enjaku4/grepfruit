require "pathname"
require "find"

module Grepfruit
  class Search
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
          print "#{COLORS[:red]}M#{COLORS[:reset]}"
        else
          print "#{COLORS[:green]}.#{COLORS[:reset]}"
        end
      end

      display_results(lines, files, files_with_matches)
    end

    COLORS = { cyan: "\e[36m", red: "\e[31m", green: "\e[32m", reset: "\e[0m" }
    private_constant :COLORS

    private

    def not_searchable?(path)
      File.directory?(path) || File.symlink?(path)
    end

    def process_file(path, lines)
      lines_size = lines.size

      File.foreach(path).with_index do |line, line_num|
        next if !line.valid_encoding? || !line.match?(regex) || excluded_line?(path, line_num)

        lines << "#{COLORS[:cyan]}#{relative_path_with_line_num(path, line_num)}#{COLORS[:reset]}: #{processed_line(line)}"
      end

      lines.size > lines_size
    end

    def display_results(lines, files, files_with_matches)
      puts "\n\n" if files.positive?

      if lines.empty?
        puts "#{number_of_files(files)} checked, #{COLORS[:green]}no matches found#{COLORS[:reset]}"
        exit(0)
      else
        puts "Matches:\n\n#{lines.join("\n")}\n\n"
        puts "#{number_of_files(files)} checked, #{COLORS[:red]}#{number_of_matches(lines.size)} found in #{number_of_files(files_with_matches)}#{COLORS[:reset]}"
        exit(1)
      end
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

    def relative_path(path)
      Pathname.new(path).relative_path_from(Pathname.new(dir)).to_s
    end

    def relative_path_with_line_num(path, line_num)
      "#{relative_path(path)}:#{line_num + 1}"
    end

    def processed_line(line)
      stripped_line = line.strip
      truncate && stripped_line.length > truncate ? "#{stripped_line[0..truncate - 1]}..." : stripped_line
    end

    def hidden?(path)
      File.basename(path).start_with?(".")
    end

    def number_of_files(num)
      "#{num} file#{'s' if num > 1}"
    end

    def number_of_matches(num)
      "#{num} match#{'es' if num > 1}"
    end
  end
end
