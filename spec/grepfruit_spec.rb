RSpec.describe Grepfruit do
  context "when all parameters are not specified" do
    subject { `./exe/grepfruit` }

    it { is_expected.to include("Searching for /TODO/...") }
    it { is_expected.to include("README.md:31") }
    it { is_expected.to include("Search for the pattern `TODO` in the current directory, excluding the default directories:") }
    it { is_expected.to include("18 files checked") }
    it { is_expected.to include("6 matches found") }
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
    it { is_expected.to include("61 matches found") }
  end

  context "when multiple directories and files are excluded" do
    subject { `./exe/grepfruit -e 'exe,spec,README.md,vendor'` }

    it { is_expected.not_to include("exe/grepfruit") }
    it { is_expected.not_to include("README.md") }
    it { is_expected.to include("no matches found") }
  end

  context "when a relative path is specified" do
    subject { `./exe/grepfruit -e 'exe/grepfruit,vendor'` }

    it { is_expected.not_to include("exe/grepfruit") }
    it { is_expected.to include("5 matches found") }
  end

  context "when only a part of the file name is excluded" do
    subject { `./exe/grepfruit -e 'fruit,vendor'` }

    it { is_expected.to include("exe/grepfruit") }
  end
end
