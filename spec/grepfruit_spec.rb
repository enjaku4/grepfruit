require "fileutils"

RSpec.describe Grepfruit do
  before do
    FileUtils.mkdir_p("tmp")
    File.write("tmp/foo.txt", "TODO: bar")
  end

  after do
    File.delete("tmp/foo.txt")
  end

  context "when all parameters are not specified" do
    subject { `./exe/grepfruit` }

    it { is_expected.to include("Searching for /TODO/...") }
    it { is_expected.to include("README.md:36") }
    it { is_expected.to include("exe/grepfruit:10") }
    it { is_expected.to include("Search for the pattern `TODO` in the current directory, excluding the default directories:") }
    it { is_expected.to include("18 files checked") }
    it { is_expected.to include("10 matches found") }
    it { is_expected.not_to include("tmp/foo.txt:") }
    it { is_expected.not_to include(".github") }
  end

  context "when only one match is found" do
    subject { `./exe/grepfruit ./exe` }

    it { is_expected.to include("1 file checked") }
    it { is_expected.to include("1 match found") }
  end

  context "when no matches are found" do
    subject { `./exe/grepfruit -e grepfruit_spec.rb -r FOOBAR` }

    it { is_expected.to include("no matches found") }
  end

  context "when regex is specified" do
    subject { `./exe/grepfruit -r 'opts|spec' -e vendor` }

    it { is_expected.to include("Searching for /opts|spec/...") }
    it { is_expected.to include("grepfruit.gemspec:5") }
    it { is_expected.to include("OptionParser.new do |opts|") }
    it { is_expected.to include("62 matches found") }
  end

  context "when multiple directories and files are excluded" do
    subject { `./exe/grepfruit -e 'exe,spec,README.md,vendor,tmp'` }

    it { is_expected.not_to include("exe/grepfruit") }
    it { is_expected.not_to include("README.md") }
    it { is_expected.to include("no matches found") }
  end

  context "when nothing is excluded" do
    subject { `./exe/grepfruit -e ''` }

    it { is_expected.to include("tmp/foo.txt:1") }
    it { is_expected.to include("TODO: bar") }
  end

  context "when a relative path is specified" do
    subject { `./exe/grepfruit -e 'exe/grepfruit,vendor'` }

    it { is_expected.not_to include("exe/grepfruit") }
    it { is_expected.to include("10 matches found") }
  end

  context "when only a part of the file name is excluded" do
    subject { `./exe/grepfruit -e 'fruit,vendor'` }

    it { is_expected.to include("exe/grepfruit") }
  end

  context "when hidden files search is enabled" do
    subject { `./exe/grepfruit -r 'bundler-cache' --search-hidden` }

    it { is_expected.to include(".github/workflows/main.yml:21") }
    it { is_expected.to include("bundler-cache: true") }
  end

  context "when hidden files search is enabled and a hidden file is excluded" do
    subject { `./exe/grepfruit -r 'package-ecosystem' -e '.github/dependabot.yml' --search-hidden` }

    it { is_expected.not_to include("dependabot.yml:") }
    it { is_expected.to include("package-ecosystem") }
  end
end
