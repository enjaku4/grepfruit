module Grepfruit
  class SearchResults
    attr_reader :raw_matches, :total_files_with_matches, :match_count
    attr_accessor :total_files

    def initialize
      @raw_matches = []
      @total_files = 0
      @total_files_with_matches = 0
      @match_count = 0
    end

    def increment_files_with_matches
      @total_files_with_matches += 1
    end

    def add_match_count(count)
      @match_count += count
    end

    def add_raw_matches(matches)
      @raw_matches.concat(matches)
    end
  end
end
