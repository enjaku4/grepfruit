require_relative "cli_decorator"

module Grepfruit
  class CliSearch < Search
    include Grepfruit::CliDecorator

    def execute
      puts "Error: Path '#{path}' does not exist." and exit 1 unless File.exist?(path)

      unless json
        puts "Searching for #{regex.inspect} in #{path.inspect}..."
        puts
      end

      results = execute_search

      if json
        display_json_results(build_result_hash(results))
      else
        display_results(results)
      end

      exit(results.match_count.positive? ? 1 : 0)
    end

    private

    def emit_file_progress(has_matches)
      return if json

      print_file_progress_dot(has_matches)
    end
  end
end
