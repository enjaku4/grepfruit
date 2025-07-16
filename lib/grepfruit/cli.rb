require "dry/cli"

module Grepfruit
  module Commands
    extend Dry::CLI::Registry

    class Search < Dry::CLI::Command
      desc "Search for regex patterns in files"

      argument :path, required: false, default: ".", desc: "Directory or file to search in"

      option :regex, aliases: ["-r"], required: true, desc: "Regex pattern to search for"
      option :exclude, aliases: ["-e"], type: :array, default: [], desc: "Comma-separated list of files and directories to exclude"
      option :include, aliases: ["-i"], type: :array, default: [], desc: "Comma-separated list of file patterns to include (only these files will be searched)"
      option :truncate, aliases: ["-t"], type: :integer, desc: "Truncate output to N characters"
      option :search_hidden, type: :boolean, default: false, desc: "Search hidden files and directories"
      option :jobs, aliases: ["-j"], type: :integer, desc: "Number of parallel workers (default: all CPU cores, use 1 for sequential)"
      option :json, type: :boolean, default: false, desc: "Output results in JSON format"

      def call(path: ".", **options)
        validate_options!(options)

        Grepfruit::Search.new(
          dir: path,
          regex: create_regex(options[:regex]),
          exclude: options[:exclude] || [],
          include: options[:include] || [],
          truncate: options[:truncate]&.to_i,
          search_hidden: options[:search_hidden],
          jobs: options[:jobs]&.to_i,
          json_output: options[:json]
        ).run
      end

      private

      def validate_options!(options)
        error_exit("You must specify a regex pattern using the -r or --regex option.") unless options[:regex]

        return unless (jobs = options[:jobs]&.to_i) && jobs < 1

        error_exit("Number of jobs must be at least 1")
      end

      def create_regex(pattern)
        Regexp.new(pattern)
      rescue RegexpError => e
        error_exit("Invalid regex pattern - #{e.message}")
      end

      def error_exit(message)
        puts "Error: #{message}"
        exit 1
      end
    end

    register "search", Search, aliases: ["s"]
  end

  class CLI < Dry::CLI
    def self.start(argv = ARGV)
      Dry::CLI.new(Commands).call(arguments: argv)
    end
  end
end
