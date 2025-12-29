require_relative "grepfruit/version"
require_relative "grepfruit/search_results"
require_relative "grepfruit/search"
require_relative "grepfruit/programmatic_search"
require_relative "grepfruit/cli"
require_relative "grepfruit/cli_search"

module Grepfruit
  def self.search(regex:, path: ".", exclude: [], include: [], truncate: nil, search_hidden: false, jobs: nil, count: false)
    raise ArgumentError, "regex is required" unless regex.is_a?(Regexp)
    raise ArgumentError, "path must be a string" unless path.is_a?(String)
    raise ArgumentError, "exclude must be an array" unless exclude.is_a?(Array)
    raise ArgumentError, "include must be an array" unless include.is_a?(Array)
    raise ArgumentError, "truncate must be a positive integer" if truncate && (!truncate.is_a?(Integer) || truncate <= 0)
    raise ArgumentError, "search_hidden must be a boolean" unless [true, false].include?(search_hidden)
    raise ArgumentError, "count must be a boolean" unless [true, false].include?(count)
    raise ArgumentError, "jobs must be at least 1" if jobs && (!jobs.is_a?(Integer) || jobs < 1)

    ProgrammaticSearch.new(
      dir: path,
      regex: regex,
      exclude: exclude,
      include: include,
      truncate: truncate,
      search_hidden: search_hidden,
      jobs: jobs,
      json_output: false,
      count_only: count
    ).execute
  end
end
