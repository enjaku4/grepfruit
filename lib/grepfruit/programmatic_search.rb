module Grepfruit
  class ProgrammaticSearch < Search
    def execute
      raise ArgumentError, "directory '#{path}' does not exist." unless File.exist?(path)

      build_result_hash(execute_search)
    end
  end
end
