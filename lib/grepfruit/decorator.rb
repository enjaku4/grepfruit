module Grepfruit
  module Decorator
    COLORS = { cyan: "\e[36m", red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze
    private_constant :COLORS

    private

    def green(text)
      "#{COLORS[:green]}#{text}#{COLORS[:reset]}"
    end

    def red(text)
      "#{COLORS[:red]}#{text}#{COLORS[:reset]}"
    end

    def cyan(text)
      "#{COLORS[:cyan]}#{text}#{COLORS[:reset]}"
    end

    def number_of_files(num)
      "#{num} file#{'s' if num > 1}"
    end

    def number_of_matches(num)
      "#{num} match#{'es' if num > 1}"
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

    def decorated_line(path, line_num, line)
      "#{cyan(relative_path_with_line_num(path, line_num))}: #{processed_line(line)}"
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
