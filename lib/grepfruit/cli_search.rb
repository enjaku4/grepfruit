require_relative "cli_decorator"

module Grepfruit
  class CliSearch < Search
    include Grepfruit::CliDecorator

    def execute
      puts "Error: Directory '#{dir}' does not exist." and exit 1 unless File.exist?(dir)

      puts "Searching for #{regex.inspect} in #{dir.inspect}..." unless json_output

      display_final_results(execute_search)
    end

    private

    def display_final_results(results)
      if json_output
        display_json_results(build_result_hash(results))
      else
        display_results(results)
      end

      exit(results.match_count.positive? ? 1 : 0)
    end

    def process_worker_result(worker_result, results)
      file_results, has_matches, match_count = worker_result

      return false unless has_matches

      results.add_match_count(match_count)
      results.add_raw_matches(file_results)

      unless json_output || count_only
        colored_lines = file_results.map do |relative_path, line_num, line_content|
          "#{cyan("#{relative_path}:#{line_num}")}: #{processed_line(line_content)}"
        end
        results.add_lines(colored_lines)
      end

      true
    end
  end
end
