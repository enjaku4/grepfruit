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
      option :search_hidden, type: :flag, default: false, desc: "Search hidden files and directories"
      option :jobs, aliases: ["-j"], type: :integer, desc: "Number of parallel workers (default: all CPU cores, use 1 for sequential)"
      option :json, type: :flag, default: false, desc: "Output results in JSON format"
      option :count, aliases: ["-c"], type: :flag, default: false, desc: "Show only counts, not match details"

      def call(path: ".", **options)
        validate_options!(options)

        begin
          regex_pattern = Grepfruit.send(:create_regex, options[:regex])
        rescue ArgumentError => e
          error_exit(e.message)
        end

        Grepfruit::Search.new(
          dir: path,
          regex: regex_pattern,
          exclude: options[:exclude] || [],
          include: options[:include] || [],
          truncate: options[:truncate]&.to_i,
          search_hidden: options[:search_hidden],
          jobs: options[:jobs]&.to_i,
          json_output: options[:json],
          count_only: options[:count]
        ).run
      end

      private

      def validate_options!(options)
        error_exit("You must specify a regex pattern using the -r or --regex option.") unless options[:regex]
        error_exit("Number of jobs must be at least 1") if (jobs = options[:jobs]&.to_i) && jobs < 1
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
