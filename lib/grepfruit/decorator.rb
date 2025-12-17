module Grepfruit
  module Decorator
    COLORS = { cyan: "\e[36m", red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze

    private

    def colorize(text, color) = "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    def green(text) = colorize(text, :green)
    def red(text) = colorize(text, :red)
    def cyan(text) = colorize(text, :cyan)

    def number_of_files(num) = "#{num} file#{'s' if num != 1}"
    def number_of_matches(num) = "#{num} match#{'es' if num != 1}"

    def processed_line(line)
      stripped = line.strip
      truncate && stripped.length > truncate ? "#{stripped[0...truncate]}..." : stripped
    end

    def display_results(lines, files, files_with_matches, total_matches)
      puts "" if files.positive?

      if total_matches.zero?
        puts "#{number_of_files(files)} checked, #{green('no matches found')}"
        exit(0)
      else
        puts "Matches:\n\n#{lines.join("\n")}\n\n" unless lines.empty?
        puts "#{number_of_files(files)} checked, #{red("#{number_of_matches(total_matches)} found in #{number_of_files(files_with_matches)}")}"
        exit(1)
      end
    end

    def display_json_results(result_hash)
      require "json"

      result_hash[:search][:pattern] = result_hash[:search][:pattern].inspect
      result_hash[:search][:timestamp] = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")

      puts JSON.pretty_generate(result_hash)

      exit(result_hash[:summary][:total_matches].zero? ? 0 : 1)
    end
  end
end
