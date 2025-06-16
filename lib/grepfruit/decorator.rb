module Grepfruit
  module Decorator
    COLORS = { cyan: "\e[36m", red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze

    private

    def green(text) = "#{COLORS[:green]}#{text}#{COLORS[:reset]}"
    def red(text) = "#{COLORS[:red]}#{text}#{COLORS[:reset]}"
    def cyan(text) = "#{COLORS[:cyan]}#{text}#{COLORS[:reset]}"

    def number_of_files(num) = "#{num} file#{'s' if num != 1}"
    def number_of_matches(num) = "#{num} match#{'es' if num != 1}"

    def relative_path(path)
      path.delete_prefix("#{dir}/")
    end

    def processed_line(line)
      stripped_line = line.strip
      truncate && stripped_line.length > truncate ? "#{stripped_line[0...truncate]}..." : stripped_line
    end

    def display_results(lines, files, files_with_matches)
      puts "\n\n" if files.positive?

      if lines.empty?
        puts "#{number_of_files(files)} checked, #{green('no matches found')}"
        exit(0)
      else
        puts "Matches:\n\n#{lines.join("\n")}\n\n"
        puts "#{number_of_files(files)} checked, #{red("#{number_of_matches(lines.size)} found in #{number_of_files(files_with_matches)}")}"
        exit(1)
      end
    end
  end
end
