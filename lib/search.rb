require "pathname"
require "find"

module Grepfruit
  class Search
    CYAN = "\e[36m"
    RED = "\e[31m"
    GREEN = "\e[32m"
    RESET = "\e[0m"

    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :truncate, :search_hidden

    def initialize(dir:, regex:, exclude:, truncate:, search_hidden:)
      @dir = dir
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.map { _1.split("/") }.partition { _1.last.include?(":") }
      @truncate = truncate
      @search_hidden = search_hidden
    end

    def run
      lines, files = [], 0

      puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n"

      Find.find(dir) do |path|
        Find.prune if excluded_path?(path) || !search_hidden && hidden?(path)

        next if File.directory?(path) || File.symlink?(path)

        files += 1

        match = false

        File.foreach(path).with_index do |line, line_num|
          next unless line.valid_encoding?

          if line.match?(regex) && !excluded_line?(path, line_num)
            lines << "#{CYAN}#{relative_path_with_line_num(path, line_num)}#{RESET}: #{processed_line(line)}"
            match = true
          end
        end

        print match ? "#{RED}M#{RESET}" : "#{GREEN}.#{RESET}"
      end

      puts "\n\n" if files.positive?

      if lines.empty?
        puts "#{number_of_files(files)} checked, #{GREEN}no matches found#{RESET}"
        exit(0)
      else
        puts "Matches:\n\n"
        puts "#{lines.join("\n")}\n\n"
        puts "#{number_of_files(files)} checked, #{RED}#{number_of_matches(lines.size)} found#{RESET}"
        exit(1)
      end
    end

    private

    def excluded_path?(path)
      excluded?(excluded_paths, relative_path(path))
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
