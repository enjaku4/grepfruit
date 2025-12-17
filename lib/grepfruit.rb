require_relative "grepfruit/version"
require_relative "grepfruit/decorator"
require_relative "grepfruit/search_results"
require_relative "grepfruit/search"
require_relative "grepfruit/cli"

module Grepfruit
  class Error < StandardError; end

  def self.search(path: ".", regex:, exclude: [], include: [], truncate: nil, search_hidden: false, jobs: nil)
    validate_search_params!(regex: regex, jobs: jobs)
    
    Search.new(
      dir: path,
      regex: regex,
      exclude: exclude,
      include: include,
      truncate: truncate,
      search_hidden: search_hidden,
      jobs: jobs,
      json_output: false
    ).execute
  end

  private

  def self.validate_search_params!(regex:, jobs:)
    raise ArgumentError, "regex is required" unless regex.is_a?(Regexp)
    raise ArgumentError, "jobs must be at least 1" if jobs && jobs < 1
  end

  def self.create_regex(pattern)
    Regexp.new(pattern)
  rescue RegexpError => e
    raise ArgumentError, "Invalid regex pattern - #{e.message}"
  end
end
