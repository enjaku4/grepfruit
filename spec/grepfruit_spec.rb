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

    it { is_expected.to include("Error: You must specify a regex pattern using the -r or --regex option.") }
  end

  context "when regex is specified" do
    subject { `./exe/grepfruit -r 'TODO' -e 'tmp,vendor,Gemfile.lock'` }

    it { is_expected.to include("Searching for /TODO/ in #{Dir.pwd.inspect}...") }
    it { is_expected.to include("README.md:43") }
    it { is_expected.to include("spec/grepfruit_spec.rb:6") }
    it { is_expected.to include("TODO: bar") }
    it { is_expected.to include("17 files checked") }
    it { is_expected.to include("25 matches found") }
    it { is_expected.to include("subject { `./exe/grepfruit -r 'TODO' -e 'vendor'` }") }
    it { is_expected.not_to include("tmp/foo.txt:") }
    it { is_expected.not_to include(".github") }
    it { is_expected.not_to include("vendor/") }
  end

  context "when full option names are specified" do
    subject { `./exe/grepfruit --regex 'TODO' --exclude 'tmp,vendor,Gemfile.lock'` }

    it { is_expected.to include("Searching for /TODO/ in #{Dir.pwd.inspect}...") }
    it { is_expected.to include("README.md:43") }
    it { is_expected.to include("spec/grepfruit_spec.rb:6") }
    it { is_expected.to include("TODO: bar") }
    it { is_expected.to include("17 files checked") }
    it { is_expected.to include("25 matches found") }
    it { is_expected.to include("subject { `./exe/grepfruit -r 'TODO' -e 'vendor'` }") }
    it { is_expected.not_to include("tmp/foo.txt:") }
    it { is_expected.not_to include(".github") }
    it { is_expected.not_to include("vendor/") }
  end

  context "when more complex regex is specified" do
    subject { `./exe/grepfruit -r 'opts|spec' -e vendor` }

    it { is_expected.to include("Searching for /opts|spec/ in #{Dir.pwd.inspect}...") }
    it { is_expected.to include("grepfruit.gemspec:5") }
    it { is_expected.to include("OptionParser.new do |opts|") }
    it { is_expected.to include("76 matches found") }
  end

  context "when only one match is found" do
    subject { `./exe/grepfruit -r 'TODO' ./tmp` }

    it { is_expected.to include("1 file checked") }
    it { is_expected.to include("1 match found") }
  end

  context "when no matches are found" do
    subject { `./exe/grepfruit -e 'grepfruit_spec.rb,vendor,Gemfile.lock' -r FOOBAR` }

    it { is_expected.to include("17 files checked") }
    it { is_expected.to include("no matches found") }
  end

  context "when no matches are found and 1 file is checked" do
    subject { `./exe/grepfruit -e grepfruit_spec.rb -r FOOBAR ./tmp` }

    it { is_expected.to include("1 file checked") }
    it { is_expected.to include("no matches found") }
  end

  context "when multiple directories and files are excluded" do
    subject { `./exe/grepfruit -e 'spec,README.md,vendor,tmp' -r TODO` }

    it { is_expected.not_to include("spec/") }
    it { is_expected.not_to include("README.md") }
    it { is_expected.to include("no matches found") }
  end

  context "when nothing is excluded" do
    subject { `./exe/grepfruit -r TODO` }

    it { is_expected.to include("tmp/foo.txt:1") }
    it { is_expected.to include("TODO: bar") }
  end

  context "when a relative path is specified" do
    subject { `./exe/grepfruit -r 'TODO' -e 'spec/grepfruit_spec.rb,vendor'` }

    it { is_expected.not_to include("spec/grepfruit_spec.rb:") }
    it { is_expected.to include("10 matches found") }
  end

  context "when only a part of the file name is excluded" do
    subject { `./exe/grepfruit -e 'spec.rb,vendor' -r TODO` }

    it { is_expected.to include("spec.rb") }
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

  context "when truncation is enabled" do
    subject { `./exe/grepfruit -r 'TODO' -t 5` }

    it { is_expected.to include("Grepf...") }
    it { is_expected.to include("subje...") }
  end
end
