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

    def display_results(results)
      puts "" if results.total_files.positive?

      if results.match_count.zero?
        puts "#{number_of_files(results.total_files)} checked, #{green('no matches found')}"
      else
        puts "#{results.all_lines.join("\n")}\n\n" unless results.all_lines.empty?
        puts "#{number_of_files(results.total_files)} checked, #{red("#{number_of_matches(results.match_count)} found in #{number_of_files(results.total_files_with_matches)}")}"
      end
    end

    def display_json_results(result_hash)
      require "json"

      result_hash[:search][:pattern] = result_hash[:search][:pattern].inspect
      result_hash[:search][:timestamp] = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")

      puts JSON.pretty_generate(result_hash)
    end
  end
end