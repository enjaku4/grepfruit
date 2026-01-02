module Grepfruit
  class ProgrammaticSearch < Search
    def execute
      raise ArgumentError, "Directory '#{dir}' does not exist." unless File.exist?(dir)

      build_result_hash(execute_search)
    end
  end
end
