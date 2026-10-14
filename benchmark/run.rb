# Times this checkout's grepfruit against the latest installed release on a pinned copy of Ruby's
# source code. Prints a table, and on GitHub Actions also writes it to the workflow run's summary page.
#
#   gem install grepfruit
#   ruby benchmark/run.rb

require "etc"
require "json"
require "rbconfig"
require "tmpdir"

CORPUS_REPOSITORY = "https://github.com/ruby/ruby"
CORPUS_TAG = "v4.0.6"
SEARCHES = {
  "Plain phrase" => "def initialize",
  "Regex" => "def [a-z_]+_(path|url)\\b",
  "No matches" => "grepfruit_benchmark_no_match"
}.freeze
WARMUP_ROUNDS = 2
ROUNDS = 10
NO_CHANGE_MARGIN = 0.1
ICONS = { faster: "🟢", same: "⚪", slower: "🔴" }.freeze

Version = Data.define(:name, :executable)

Result = Data.define(:label, :pattern, :current_lines, :previous_lines, :current_time, :previous_time) do
  def speedup = previous_time / current_time

  def status
    if speedup >= 1 + NO_CHANGE_MARGIN
      :faster
    elsif speedup <= 1 / (1 + NO_CHANGE_MARGIN)
      :slower
    else
      :same
    end
  end

  def change = speedup >= 1 ? format("%.2f× faster", speedup) : format("%.2f× slower", 1 / speedup)
end

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

def lines(result, release)
  return delimited(result.current_lines) if result.current_lines == result.previous_lines

  "#{delimited(result.current_lines)} (#{release.version}: #{delimited(result.previous_lines)})"
end

def headline(results, release)
  slower = results.count { _1.status == :slower }
  overall = results.map(&:speedup).reduce(:*)**(1.0 / results.size)

  if slower.positive?
    "#{ICONS[:slower]} Slower than #{release.version} in #{slower} of #{results.size} searches"
  elsif overall >= 1 + NO_CHANGE_MARGIN
    "#{ICONS[:faster]} #{format('%.2f', overall)}× faster than #{release.version}"
  else
    "#{ICONS[:same]} About the same speed as #{release.version}"
  end
end

def text_report(results, release, environment)
  # The icon goes in the last column: it is two cells wide on screen, which would misalign any column after it
  rows = [["Search", "", "Matching lines", "This commit", release.version.to_s, "Change"]] +
         results.map { [_1.label, _1.pattern, lines(_1, release), duration(_1.current_time), duration(_1.previous_time), "#{ICONS[_1.status]} #{_1.change}"] }
  widths = rows.transpose.map { |column| column.map(&:length).max }
  right_aligned = [2, 3, 4]
  table = rows.map do |row|
    row.each_with_index.map { |cell, index| right_aligned.include?(index) ? cell.rjust(widths[index]) : cell.ljust(widths[index]) }.join("  ").rstrip
  end

  [headline(results, release), "", *table, "", environment].join("\n")
end

def markdown_report(results, release, environment)
  rows = results.map do |result|
    # A pipe inside a table cell ends the cell, even within a code span, unless escaped
    pattern = "`#{result.pattern.gsub('|', '\|')}`"
    current, previous = [result.current_time, result.previous_time].map { duration(_1) }
    current, previous = result.current_time <= result.previous_time ? ["**#{current}**", previous] : [current, "**#{previous}**"]

    "| #{ICONS[result.status]} | #{result.label} | #{pattern} | #{lines(result, release)} | #{current} | #{previous} | #{result.change} |"
  end

  <<~MARKDOWN
    ### #{headline(results, release)}

    | | Search | Pattern | Matching lines | This commit | #{release.version} | Change |
    | :-: | --- | --- | ---: | ---: | ---: | --- |
    #{rows.join("\n")}

    <details><summary>How this was measured</summary>

    #{environment}

    </details>
  MARKDOWN
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
  SEARCHES.values.product(versions) do |pattern, version|
    time = elapsed(command(version, corpus, pattern))
    timings[[pattern, version]] << time if round >= WARMUP_ROUNDS
  end
end

results = SEARCHES.map do |label, pattern|
  current_lines, previous_lines = versions.map { matching_lines(_1, corpus, pattern) }
  current_time, previous_time = versions.map { median(timings[[pattern, _1]]) }

  Result.new(label:, pattern:, current_lines:, previous_lines:, current_time:, previous_time:)
end

files = Dir.glob("**/*", base: corpus).map { File.join(corpus, _1) }.select { File.file?(_1) }
environment = "Searched Ruby's source code at #{CORPUS_TAG} (#{delimited(files.size)} files, #{(files.sum { File.size(_1) } / 1_000_000.0).round} MB) " \
              "with Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}, #{Etc.nprocessors} CPUs. Each time is the median of #{ROUNDS} runs " \
              "after #{WARMUP_ROUNDS} warm-ups, alternating between the two versions. Changes under #{(NO_CHANGE_MARGIN * 100).round}% " \
              "are marked #{ICONS[:same]} to allow for run-to-run variation."

puts text_report(results, release, environment)

File.write(ENV.fetch("GITHUB_STEP_SUMMARY"), markdown_report(results, release, environment), mode: "a") if ENV.key?("GITHUB_STEP_SUMMARY")
