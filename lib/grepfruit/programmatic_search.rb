module Grepfruit
  class ProgrammaticSearch < Search
    def execute
      puts "Error: Directory '#{dir}' does not exist." unless File.exist?(dir)

      build_result_hash(execute_search)
    end

    private

    def process_worker_result(worker_result, results)
      file_results, has_matches, match_count = worker_result

      return false unless has_matches

      results.add_match_count(match_count)
      results.add_raw_matches(file_results)

      true
    end
  end
end
