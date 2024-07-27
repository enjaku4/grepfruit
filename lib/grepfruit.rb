require_relative "grepfruit/version"
require "pathname"
require "find"

module Grepfruit
  def self.run(path:, regex:, exclude:)
    lines = []
    files = 0
    dir = path

    puts "Searching for #{regex.inspect}...\n\n"

    Find.find(dir) do |file|
      basename = File.basename(file)

      if exclude.include?(basename) || basename.start_with?(".")
        File.directory?(path) ? Find.prune : next
      end

      next if File.directory?(file)

      files += 1

      match = false

      File.foreach(file).with_index do |line, line_num|
        next unless line.valid_encoding?

        if line.match?(regex)
          lines << "\e[36m#{Pathname.new(file).relative_path_from(Pathname.new(dir))}:#{line_num + 1}\e[0m: #{line.strip}"
          match = true
        end
      end

      print match ? "\e[31mF\e[0m" : "\e[32m.\e[0m"
    end

    puts "\n\n"

    if lines.empty?
      puts "#{files} files checked, \e[32mno matches found\e[0m"
      exit(0)
    else
      puts "Matches:\n\n"
      puts "#{lines.join("\n")}\n\n"
      puts "#{files} files checked, \e[31m#{lines.size} match#{'es' if lines.size > 1} found\e[0m"
      exit(1)
    end
  end
end
