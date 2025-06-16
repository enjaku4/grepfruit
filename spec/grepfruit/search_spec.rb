require "fileutils"

RSpec.describe Grepfruit::Search do
  context "when no parameters are specified" do
    subject { `./exe/grepfruit 2>&1` }

    it { is_expected.to include("Commands:") }
  end

  describe "basic search functionality" do
    context "when path is specified" do
      subject { `./exe/grepfruit search -r 'TODO' ./spec/test_dataset` }

      it { is_expected.to include(%r{Searching for /TODO/ in ".+/spec/test_dataset"...}) }
      it { is_expected.to include("4 files checked") }
      it { is_expected.to include("16 matches found") }
      it { is_expected.to include("in 4 files") }
      it { is_expected.not_to include(".hidden") }
    end

    context "when no path specified (defaults to current directory)" do
      subject { `./exe/grepfruit search -r TODO` }

      it { is_expected.to include("Searching for /TODO/ in #{Dir.pwd.inspect}...") }
      it { is_expected.to include("matches found") }
    end

    context "when no matches found" do
      subject { `./exe/grepfruit search -r FOOBAR ./spec/test_dataset` }

      it { is_expected.to include("4 files checked") }
      it { is_expected.to include("no matches found") }
    end
  end

  describe "regex patterns and options" do
    context "when complex regex is specified" do
      subject { `./exe/grepfruit search -r 'TODO|FIXME' ./spec/test_dataset` }

      it { is_expected.to include("17 matches found") }
      it { is_expected.to include("in 4 files") }
    end

    context "when using full option names" do
      subject { `./exe/grepfruit search --regex 'TODO' ./spec/test_dataset` }

      it { is_expected.to include("16 matches found") }
      it { is_expected.to include("4 files checked") }
    end

    context "when case-sensitive search" do
      subject { `./exe/grepfruit search -r 'todo' ./spec/test_dataset` }

      it { is_expected.to include("no matches found") }
    end

    context "when case-insensitive regex with flags" do
      subject { `./exe/grepfruit search -r '(?i)todo' ./spec/test_dataset` }

      it { is_expected.to include("matches found") }
    end
  end

  describe "file filtering and exclusion" do
    context "when files and directories are excluded" do
      subject { `./exe/grepfruit search -e 'folder,bar.txt' -r TODO ./spec/test_dataset` }

      it { is_expected.not_to include("folder/") }
      it { is_expected.not_to include("bar.txt") }
      it { is_expected.to include("foo.md") }
    end

    context "when using full option name --exclude" do
      subject { `./exe/grepfruit search --exclude 'folder,bar.txt' -r TODO ./spec/test_dataset` }

      it { is_expected.not_to include("folder/") }
      it { is_expected.not_to include("bar.txt") }
    end

    context "when specific line is excluded" do
      subject { `./exe/grepfruit search -r 'TODO' -e 'bar.txt:14' ./spec/test_dataset` }

      it { is_expected.not_to include("bar.txt:14") }
    end

    context "when hidden files search is enabled" do
      subject { `./exe/grepfruit search -r 'TODO' --search-hidden ./spec/test_dataset` }

      it { is_expected.to include(".hidden:2") }
    end

    context "when hidden file is excluded from search" do
      subject { `./exe/grepfruit search -r 'TODO' -e '.hidden' --search-hidden ./spec/test_dataset` }

      it { is_expected.not_to include(".hidden") }
    end
  end

  describe "output formatting" do
    context "when single file with single match" do
      subject { `./exe/grepfruit search -r 'FIXME' ./spec/test_dataset/baz.py` }

      it { is_expected.to include("1 file checked") }
      it { is_expected.to include("1 match found") }
      it { is_expected.to include("in 1 file") }
    end

    context "when truncation is enabled" do
      subject { `./exe/grepfruit search -r 'TODO' -t 15 ./spec/test_dataset` }

      it { is_expected.to include("TODO: Add unit ...") }
      it { is_expected.to include("TODO: Update th...") }
    end

    context "when using full option name --truncate" do
      subject { `./exe/grepfruit search -r 'TODO' --truncate 15 ./spec/test_dataset` }

      it { is_expected.to include("TODO: Add unit ...") }
    end
  end

  describe "error handling" do
    context "when no regex is specified" do
      subject { `./exe/grepfruit search ./spec/test_dataset 2>&1` }

      it { is_expected.to include("Error: You must specify a regex pattern using the -r or --regex option.") }
    end

    context "when invalid regex is specified" do
      subject { `./exe/grepfruit search -r '[' ./spec/test_dataset 2>&1` }

      it { is_expected.to include("Error: Invalid regex pattern") }
      it { is_expected.to include("premature end of char-class") }
    end

    context "when invalid jobs count is specified" do
      subject { `./exe/grepfruit search -r 'TODO' -j 0 ./spec/test_dataset 2>&1` }

      it { is_expected.to include("Error: Number of jobs must be at least 1") }
    end
  end

  describe "parallel processing" do
    context "when jobs flag is used with 1 worker" do
      subject { `./exe/grepfruit search -r 'TODO' -j 1 ./spec/test_dataset` }

      it { is_expected.to include("Searching for /TODO/ in") }
      it { is_expected.to include("16 matches found") }
      it { is_expected.to include("4 files checked") }
    end

    context "when jobs flag is used with multiple workers" do
      subject { `./exe/grepfruit search -r 'TODO' -j 4 ./spec/test_dataset` }

      it { is_expected.to include("Searching for /TODO/ in") }
      it { is_expected.to include("16 matches found") }
      it { is_expected.to include("4 files checked") }
    end

    context "when using command alias 's'" do
      subject { `./exe/grepfruit s -r 'TODO' ./spec/test_dataset` }

      it { is_expected.to include("16 matches found") }
      it { is_expected.to include("4 files checked") }
    end
  end

  describe "edge cases" do
    context "when searching non-existent directory" do
      subject { `./exe/grepfruit search -r 'TODO' ./nonexistent` }

      it { is_expected.to include("0 files checked") }
      it { is_expected.to include("no matches found") }
    end

    context "when jobs count exceeds number of files" do
      subject { `./exe/grepfruit search -r 'TODO' -j 10 ./spec/test_dataset` }

      it { is_expected.to include("4 files checked") }
      it { is_expected.to include("16 matches found") }
    end
  end
end
