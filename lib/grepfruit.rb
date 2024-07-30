require_relative "grepfruit/version"
require "pathname"
require "find"

module Grepfruit
  def self.run(path:, regex:, exclude:, search_hidden:)
    lines = []
    files = 0

    puts "Searching for #{regex.inspect}...\n\n"

    Find.find(path) do |filepath|
      Find.prune if exclude.any? { |e| filepath.split("/").last(e.length) == e } || !search_hidden && File.basename(filepath).start_with?(".")

      next if File.directory?(filepath) || File.symlink?(filepath)

      files += 1

      match = false

      File.foreach(filepath).with_index do |line, line_num|
        next unless line.valid_encoding?

        if line.match?(regex)
          lines << "\e[36m#{Pathname.new(filepath).relative_path_from(Pathname.new(path))}:#{line_num + 1}\e[0m: #{line.strip}"
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
