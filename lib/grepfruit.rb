require_relative "grepfruit/version"
require "pathname"
require "find"

module Grepfruit
  def self.run(dir:, regex:, exclude:, truncate:, search_hidden:)
    lines = []
    files = 0
    excluded_lines = exclude.select { |e| e.any? { |s| s.include?(":") } }
    excluded_paths = exclude - excluded_lines

    puts "Searching for #{regex.inspect} in #{dir.inspect}...\n\n"

    Find.find(dir) do |path|
      Find.prune if excluded_paths.any? { |e| path.split("/").last(e.length) == e } || !search_hidden && File.basename(path).start_with?(".")

      next if File.directory?(path) || File.symlink?(path)

      files += 1

      match = false

      File.foreach(path).with_index do |line, line_num|
        next unless line.valid_encoding?

        if line.match?(regex)
          path_with_line = "#{Pathname.new(path).relative_path_from(Pathname.new(dir))}:#{line_num + 1}"

          next if excluded_lines.any? { |e| path_with_line.split("/").last(e.length) == e }

          processed_line = line.strip
          processed_line = "#{processed_line[0..truncate - 1]}..." if truncate && processed_line.length > truncate
          lines << "\e[36m#{path_with_line}\e[0m: #{processed_line}"
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
end
