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

    def display_json_results(raw_matches, total_files, files_with_matches)
      require "json"

      search_info = {
        pattern: regex.inspect,
        directory: dir,
        exclusions: (excluded_paths + excluded_lines).map { |path_parts| path_parts.join("/") },
        timestamp: @start_time.strftime("%Y-%m-%dT%H:%M:%S%z")
      }

      summary = {
        files_checked: total_files,
        files_with_matches: files_with_matches,
        total_matches: raw_matches.size
      }

      matches = raw_matches.map do |relative_path, line_num, line_content|
        {
          file: relative_path,
          line: line_num,
          content: line_content.strip
        }
      end

      result = {
        search: search_info,
        summary: summary,
        matches: matches
      }

      puts JSON.pretty_generate(result)

      exit(raw_matches.empty? ? 0 : 1)
    end
  end
end
