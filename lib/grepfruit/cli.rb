require "dry/cli"

module Grepfruit
  module Commands
    extend Dry::CLI::Registry

    class Search < Dry::CLI::Command
      desc "Search for regex patterns in files"

      argument :path, required: false, default: ".", desc: "Directory or file to search in"

      option :regex, aliases: ["-r"], required: true, desc: "Regex pattern to search for"
      option :exclude, aliases: ["-e"], type: :array, default: [], desc: "Comma-separated list of files and directories to exclude"
      option :truncate, aliases: ["-t"], type: :integer, desc: "Truncate output to N characters"
      option :search_hidden, type: :boolean, default: false, desc: "Search hidden files and directories"
      option :jobs, aliases: ["-j"], type: :integer, desc: "Number of parallel workers (default: all CPU cores, use 1 for sequential)"

      def call(path: ".", **options)
        unless options[:regex]
          puts "Error: You must specify a regex pattern using the -r or --regex option."
          exit 1
        end

        begin
          regex = Regexp.new(options[:regex])
        rescue RegexpError => e
          puts "Error: Invalid regex pattern - #{e.message}"
          exit 1
        end

        search_options = {
          dir: path,
          regex: regex,
          exclude: options[:exclude] || [],
          truncate: options[:truncate]&.to_i,
          search_hidden: !!options[:search_hidden],
          jobs: options[:jobs]&.to_i
        }

        Grepfruit::Search.new(**search_options).run
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
