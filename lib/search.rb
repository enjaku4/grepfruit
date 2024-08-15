require "pathname"
require "find"

module Grepfruit
  class Search
    attr_reader :dir, :regex, :excluded_paths, :excluded_lines, :truncate, :search_hidden

    def initialize(dir:, regex:, exclude:, truncate:, search_hidden:)
      @dir = dir
      @regex = regex
      @excluded_lines, @excluded_paths = exclude.partition { |e| e.include?(":") }
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

          if line.match?(regex)
            next if excluded_line?(path, line_num)

            lines << "\e[36m#{relative_path_with_line_num(path, line_num)}\e[0m: #{processed_line(line)}"
            match = true
          end
        end

        print match ? "\e[31mF\e[0m" : "\e[32m.\e[0m"
      end

      puts "\n\n"

      if lines.empty?
        puts "#{files} file#{'s' if files > 1} checked, \e[32mno matches found\e[0m"
        exit(0)
      else
        puts "Matches:\n\n"
        puts "#{lines.join("\n")}\n\n"
        puts "#{files} file#{'s' if files > 1} checked, \e[31m#{lines.size} match#{'es' if lines.size > 1} found\e[0m"
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
      list.any?(path)
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
  end
end
