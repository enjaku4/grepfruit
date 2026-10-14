# Times this checkout's grepfruit against the latest installed release on a pinned copy of Ruby's
# source code, and prints the results as a Markdown table.
#
#   gem install grepfruit
#   ruby benchmark/run.rb

require "etc"
require "json"
require "rbconfig"
require "tmpdir"

CORPUS_REPOSITORY = "https://github.com/ruby/ruby"
CORPUS_TAG = "v4.0.6"
SEARCHES = ["def initialize", "def [a-z_]+_(path|url)\\b", "grepfruit_benchmark_no_match"].freeze
WARMUP_ROUNDS = 2
ROUNDS = 10

Version = Data.define(:name, :executable)

def corpus_path
  path = File.join(Dir.tmpdir, "grepfruit-benchmark", "ruby-#{CORPUS_TAG}")
  return path if Dir.exist?(path)

  warn "Cloning #{CORPUS_REPOSITORY} #{CORPUS_TAG}..."
  system("git", "-c", "advice.detachedHead=false", "clone", "--quiet", "--depth", "1", "--branch", CORPUS_TAG, "#{CORPUS_REPOSITORY}.git", path, exception: true)
  path
end

def command(version, corpus, pattern, *flags)
  [RbConfig.ruby, version.executable, "search", *flags, "-r", pattern, corpus]
end

def matching_lines(version, corpus, pattern)
  JSON.parse(IO.popen(command(version, corpus, pattern, "--json", "--count"), &:read)).dig("summary", "total_matches")
end

def elapsed(command)
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  system(*command, out: File::NULL, err: File::NULL)
  Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
end

def median(values)
  sorted = values.sort
  (sorted[(sorted.size - 1) / 2] + sorted[sorted.size / 2]) / 2
end

def duration(seconds)
  seconds < 1 ? "#{(seconds * 1000).round} ms" : format("%.2f s", seconds)
end

def delimited(number)
  number.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
end

def comparison(current, release)
  ratio = release / current
  ratio >= 1 ? format("%.2f× faster", ratio) : format("%.2f× slower", 1 / ratio)
end

release = begin
  Gem::Specification.find_by_name("grepfruit")
rescue Gem::MissingSpecError
  abort "Install the release to compare against first: gem install grepfruit"
end

corpus = corpus_path
current = Version.new(name: "This commit", executable: File.expand_path("../exe/grepfruit", __dir__))
previous = Version.new(name: "#{release.version} (latest release)", executable: release.bin_file("grepfruit"))
versions = [current, previous]

# Rounds alternate between the two versions, so a slowdown on a shared CI runner hits both alike
timings = Hash.new { |hash, key| hash[key] = [] }
(WARMUP_ROUNDS + ROUNDS).times do |round|
  warn "Round #{round + 1} of #{WARMUP_ROUNDS + ROUNDS}#{' (warm-up)' if round < WARMUP_ROUNDS}"
  SEARCHES.product(versions) do |pattern, version|
    time = elapsed(command(version, corpus, pattern))
    timings[[pattern, version]] << time if round >= WARMUP_ROUNDS
  end
end

files = Dir.glob("**/*", base: corpus).map { File.join(corpus, _1) }.select { File.file?(_1) }
megabytes = files.sum { File.size(_1) } / 1_000_000.0

puts "## Benchmark"
puts
puts "Searching [Ruby's source code](#{CORPUS_REPOSITORY}/tree/#{CORPUS_TAG}) at #{CORPUS_TAG}: #{delimited(files.size)} files, #{megabytes.round} MB. " \
     "Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}, #{Etc.nprocessors} CPUs. Each time is the median of #{ROUNDS} runs; lower is better."
puts
puts "| Search | Matching lines | #{current.name} | #{previous.name} | Change |"
puts "| --- | ---: | ---: | ---: | ---: |"

SEARCHES.each do |pattern|
  current_lines, previous_lines = versions.map { matching_lines(_1, corpus, pattern) }
  lines = current_lines == previous_lines ? delimited(current_lines) : "#{delimited(current_lines)} (#{release.version}: #{delimited(previous_lines)})"
  current_time, previous_time = versions.map { median(timings[[pattern, _1]]) }

  # A pipe inside a table cell ends the cell, even within a code span, unless escaped
  puts "| `#{pattern.gsub('|', '\|')}` | #{lines} | #{duration(current_time)} | #{duration(previous_time)} | #{comparison(current_time, previous_time)} |"
end
