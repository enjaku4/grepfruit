require_relative "cli_decorator"

module Grepfruit
  class CliSearch < Search
    include Grepfruit::CliDecorator

    def execute
      puts "Error: Directory '#{path}' does not exist." and exit 1 unless File.exist?(path)

      puts "Searching for #{regex.inspect} in #{path.inspect}..." unless json

      results = execute_search

      if json
        display_json_results(build_result_hash(results))
      else
        display_results(results)
      end

      exit(results.match_count.positive? ? 1 : 0)
    end
  end
end
