require "fileutils"

RSpec.describe Grepfruit::Search do
  context "when no parameters are specified" do
    subject { `./exe/grepfruit 2>&1` }

    it { is_expected.to include("Commands:") }
  end

  context "when path is not specified" do
    subject { `./exe/grepfruit search -r TODO` }

    it { is_expected.to include("Searching for /TODO/ in #{Dir.pwd.inspect}...") }
  end

  context "when curent directory is specified as ." do
    subject { `./exe/grepfruit search -r TODO .` }

    it { is_expected.to include("Searching for /TODO/ in #{Dir.pwd.inspect}...") }
    it { is_expected.to include("matches found") }
  end

  context "when path is specified" do
    subject { `./exe/grepfruit search -r 'TODO' ./spec/test_dataset` }

    it { is_expected.to include(%r{Searching for /TODO/ in ".+/spec/test_dataset"...}) }
    it { is_expected.to include("bar.txt:7") }
    it { is_expected.to include("folder/bad.yml:21") }
    it { is_expected.to include("TODO: Add more details about feature 3.") }
    it { is_expected.to include("TODO: Refactor this function to improve readability") }
    it { is_expected.to include("4 files checked") }
    it { is_expected.to include("16 matches found") }
    it { is_expected.to include("in 4 files") }
    it { is_expected.not_to include(".hidden") }
  end

  context "when full option name --regex is used" do
    subject { `./exe/grepfruit search --regex 'TODO' ./spec/test_dataset` }

    it { is_expected.to include(%r{Searching for /TODO/ in ".+/spec/test_dataset"...}) }
    it { is_expected.to include("bar.txt:7") }
    it { is_expected.to include("folder/bad.yml:21") }
    it { is_expected.to include("TODO: Add more details about feature 3.") }
    it { is_expected.to include("TODO: Refactor this function to improve readability") }
    it { is_expected.to include("4 files checked") }
    it { is_expected.to include("16 matches found") }
    it { is_expected.to include("in 4 files") }
    it { is_expected.not_to include(".hidden") }
  end

  context "when more complex regex is specified" do
    subject { `./exe/grepfruit search -r 'TODO|FIXME' ./spec/test_dataset` }

    it { is_expected.to include(%r{Searching for /TODO|FIXME/ in ".+/spec/test_dataset"...}) }
    it { is_expected.to include("baz.py:42") }
    it { is_expected.to include("This function is not working as expected") }
    it { is_expected.to include("bar.txt:7") }
    it { is_expected.to include("Update the user permissions module.") }
    it { is_expected.to include("17 matches found") }
    it { is_expected.to include("in 4 files") }
  end

  context "when only one match is found and only one file is checked" do
    subject { `./exe/grepfruit search -r 'FIXME' ./spec/test_dataset/baz.py` }

    it { is_expected.to include("1 file checked") }
    it { is_expected.to include("1 match found") }
    it { is_expected.to include("in 1 file") }
  end

  context "when no matches are found" do
    subject { `./exe/grepfruit search -r FOOBAR ./spec/test_dataset` }

    it { is_expected.to include("4 files checked") }
    it { is_expected.to include("no matches found") }
  end

  context "when no matches are found and 1 file is checked" do
    subject { `./exe/grepfruit search -r FOOBAR ./spec/test_dataset/folder` }

    it { is_expected.to include("1 file checked") }
    it { is_expected.to include("no matches found") }
  end

  context "when multiple directories and files are excluded" do
    subject { `./exe/grepfruit search -e 'folder,bar.txt' -r TODO ./spec/test_dataset` }

    it { is_expected.not_to include("folder/") }
    it { is_expected.not_to include("bar.txt") }
  end

  context "when full option name --exclude is used" do
    subject { `./exe/grepfruit search --exclude 'folder,bar.txt' -r TODO ./spec/test_dataset` }

    it { is_expected.not_to include("folder/") }
    it { is_expected.not_to include("bar.txt") }
  end

  context "when nothing is excluded" do
    subject { `./exe/grepfruit search -r TODO ./spec/test_dataset` }

    it { is_expected.to include("folder/bad.yml") }
    it { is_expected.to include("bar.txt") }
    it { is_expected.to include("baz.py") }
    it { is_expected.to include("foo.md") }
  end

  context "when a relative path is excluded" do
    subject { `./exe/grepfruit search -r 'TODO' -e 'folder/bad.yml' ./spec/test_dataset` }

    it { is_expected.not_to include("bad.yml") }
  end

  context "when a specific line is excluded" do
    subject { `./exe/grepfruit search -r 'TODO' -e 'bar.txt:14' ./spec/test_dataset` }

    it { is_expected.not_to include("bar.txt:14") }
  end

  context "when only a part of the file name is excluded" do
    subject { `./exe/grepfruit search -e '.txt' -r TODO ./spec/test_dataset` }

    it { is_expected.to include("bar.txt") }
  end

  context "when truncation is enabled" do
    subject { `./exe/grepfruit search -r 'TODO' -t 15 ./spec/test_dataset` }

    it { is_expected.to include("TODO: Add unit ...") }
    it { is_expected.to include("TODO: Update th...") }
  end

  context "when full option name --truncate is used" do
    subject { `./exe/grepfruit search -r 'TODO' --truncate 15 ./spec/test_dataset` }

    it { is_expected.to include("TODO: Add unit ...") }
    it { is_expected.to include("TODO: Update th...") }
  end

  context "when hidden files search is enabled" do
    subject { `./exe/grepfruit search -r 'TODO' --search-hidden ./spec/test_dataset` }

    it { is_expected.to include(".hidden:2") }
    it { is_expected.to include("Verify if the data needs to be encrypted.") }
  end

  context "when hidden files search is enabled and a hidden file is excluded" do
    subject { `./exe/grepfruit search -r 'TODO' -e '.hidden' --search-hidden ./spec/test_dataset` }

    it { is_expected.not_to include(".hidden") }
  end

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
end
