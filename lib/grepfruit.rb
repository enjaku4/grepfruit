require_relative "grepfruit/version"
require_relative "grepfruit/decorator"
require_relative "grepfruit/search_results"
require_relative "grepfruit/search"
require_relative "grepfruit/cli"

module Grepfruit
  class Error < StandardError; end

  def self.search(regex:, path: ".", exclude: [], include: [], truncate: nil, search_hidden: false, jobs: nil, count: false)
    Search.validate_search_params!(
      regex: regex,
      path: path,
      exclude: exclude,
      include: include,
      truncate: truncate,
      search_hidden: search_hidden,
      jobs: jobs,
      count: count
    )

    Search.new(
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
