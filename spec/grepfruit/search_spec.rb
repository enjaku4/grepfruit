require "fileutils"
require "json"

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

    context "when files are excluded using wildcard patterns" do
      context "excluding files by extension" do
        subject { `./exe/grepfruit search -r 'TODO' -e '*.py' ./spec/test_dataset` }

        it { is_expected.not_to include("baz.py") }
        it { is_expected.to include("foo.md") }
        it { is_expected.to include("bar.txt") }
        it { is_expected.to include("3 files checked") }
        it { is_expected.to include("12 matches found") }
      end

      context "using wildcard pattern that matches no files" do
        subject { `./exe/grepfruit search -r 'TODO' -e '*.xyz' ./spec/test_dataset` }

        it { is_expected.to include("4 files checked") }
        it { is_expected.to include("16 matches found") }
      end

      context "mixing wildcard and exact exclusions" do
        subject { `./exe/grepfruit search -r 'TODO' -e '*.py,folder' ./spec/test_dataset` }

        it { is_expected.not_to include("baz.py") }
        it { is_expected.not_to include("folder/") }
        it { is_expected.to include("foo.md") }
        it { is_expected.to include("bar.txt") }
        it { is_expected.to include("2 files checked") }
        it { is_expected.to include("11 matches found") }
      end

      context "using ? wildcard for single character matching" do
        subject { `./exe/grepfruit search -r 'TODO' -e 'ba?.py' ./spec/test_dataset` }

        it { is_expected.not_to include("baz.py") }
        it { is_expected.to include("foo.md") }
        it { is_expected.to include("bar.txt") }
        it { is_expected.to include("3 files checked") }
        it { is_expected.to include("12 matches found") }
      end

      context "using [] wildcard for character class matching" do
        subject { `./exe/grepfruit search -r 'TODO' -e '[bf]*.txt' ./spec/test_dataset` }

        it { is_expected.not_to include("bar.txt") }
        it { is_expected.to include("baz.py") }
        it { is_expected.to include("foo.md") }
        it { is_expected.to include("3 files checked") }
        it { is_expected.to include("13 matches found") }
      end

      context "excluding by filename only" do
        subject { `./exe/grepfruit search -r 'TODO' -e 'bad.yml' ./spec/test_dataset` }

        it { is_expected.not_to include("folder/bad.yml") }
        it { is_expected.to include("baz.py") }
        it { is_expected.to include("bar.txt") }
        it { is_expected.to include("foo.md") }
        it { is_expected.to include("3 files checked") }
        it { is_expected.to include("15 matches found") }
      end
    end

    context "when files are included using patterns" do
      context "including files by extension" do
        subject { `./exe/grepfruit search -r 'TODO' -i '*.py' ./spec/test_dataset` }

        it { is_expected.to include("baz.py") }
        it { is_expected.not_to include("foo.md") }
        it { is_expected.not_to include("bar.txt") }
        it { is_expected.not_to include("folder/bad.yml") }
        it { is_expected.to include("1 file checked") }
        it { is_expected.to include("4 matches found") }
      end

      context "using wildcard pattern that matches no files" do
        subject { `./exe/grepfruit search -r 'TODO' -i '*.xyz' ./spec/test_dataset` }

        it { is_expected.to include("0 files checked") }
        it { is_expected.to include("no matches found") }
      end

      context "including multiple file types" do
        subject { `./exe/grepfruit search -r 'TODO' -i '*.py,*.txt' ./spec/test_dataset` }

        it { is_expected.to include("baz.py") }
        it { is_expected.to include("bar.txt") }
        it { is_expected.not_to include("foo.md") }
        it { is_expected.not_to include("folder/bad.yml") }
        it { is_expected.to include("2 files checked") }
        it { is_expected.to include("7 matches found") }
      end

      context "using wildcard pattern ba*.txt" do
        subject { `./exe/grepfruit search -r 'TODO' -i 'ba*.txt' ./spec/test_dataset` }

        it { is_expected.to include("bar.txt") }
        it { is_expected.not_to include("baz.py") }
        it { is_expected.not_to include("foo.md") }
        it { is_expected.not_to include("folder/bad.yml") }
        it { is_expected.to include("1 file checked") }
        it { is_expected.to include("3 matches found") }
      end

      context "combining include and exclude patterns" do
        subject { `./exe/grepfruit search -r 'TODO' -i '*.txt,*.py' -e 'ba*' ./spec/test_dataset` }

        it { is_expected.not_to include("bar.txt") }
        it { is_expected.not_to include("baz.py") }
        it { is_expected.not_to include("foo.md") }
        it { is_expected.not_to include("folder/bad.yml") }
        it { is_expected.to include("0 files checked") }
        it { is_expected.to include("no matches found") }
      end

      context "using full option name --include" do
        subject { `./exe/grepfruit search --include '*.py' -r TODO ./spec/test_dataset` }

        it { is_expected.to include("baz.py") }
        it { is_expected.not_to include("bar.txt") }
        it { is_expected.to include("1 file checked") }
        it { is_expected.to include("4 matches found") }
      end

      context "using ? wildcard for single character matching" do
        subject { `./exe/grepfruit search -r 'TODO' -i 'ba?.py' ./spec/test_dataset` }

        it { is_expected.to include("baz.py") }
        it { is_expected.not_to include("bar.txt") }
        it { is_expected.to include("1 file checked") }
        it { is_expected.to include("4 matches found") }
      end

      context "using [] wildcard for character class matching" do
        subject { `./exe/grepfruit search -r 'TODO' -i '[bf]*.txt' ./spec/test_dataset` }

        it { is_expected.to include("bar.txt") }
        it { is_expected.not_to include("baz.py") }
        it { is_expected.to include("1 file checked") }
        it { is_expected.to include("3 matches found") }
      end
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
      subject { `./exe/grepfruit search ./spec/test_dataset` }

      it { is_expected.to include("Error: You must specify a regex pattern using the -r or --regex option.") }
    end

    context "when invalid regex is specified" do
      subject { `./exe/grepfruit search -r '[' ./spec/test_dataset` }

      it { is_expected.to include("Error: Invalid regex pattern") }
      it { is_expected.to include("premature end of char-class") }
    end

    context "when invalid jobs count is specified" do
      subject { `./exe/grepfruit search -r 'TODO' -j 0 ./spec/test_dataset` }

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

  describe "JSON output" do
    context "when --json flag is used with matches found" do
      subject { `./exe/grepfruit search -r 'TODO' --json ./spec/test_dataset` }

      it "includes search metadata" do
        json = JSON.parse(subject)
        expect(json["search"]).to include(
          "pattern" => "/TODO/",
          "directory" => File.expand_path("./spec/test_dataset")
        )
        expect(json["search"]["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it "includes summary with correct counts" do
        json = JSON.parse(subject)
        expect(json["summary"]).to include(
          "files_checked" => 4,
          "files_with_matches" => 4,
          "total_matches" => 16
        )
      end

      it "includes matches with required fields" do
        json = JSON.parse(subject)
        expect(json["matches"]).to be_an(Array)
        expect(json["matches"].size).to eq(16)

        first_match = json["matches"].first
        expect(first_match).to include("file", "line", "content")
        expect(first_match["file"]).to be_a(String)
        expect(first_match["line"]).to be_a(Integer)
        expect(first_match["content"]).to be_a(String)
      end

      it "exits with code 1 when matches are found" do
        system("./exe/grepfruit search -r 'TODO' --json ./spec/test_dataset > /dev/null")
        expect($?.exitstatus).to eq(1)
      end
    end

    context "when --json flag is used with no matches" do
      subject { `./exe/grepfruit search -r 'NONEXISTENT' --json ./spec/test_dataset` }

      it "outputs valid JSON with empty matches" do
        json = JSON.parse(subject)
        expect(json["matches"]).to eq([])
        expect(json["summary"]["total_matches"]).to eq(0)
      end

      it "exits with code 0 when no matches are found" do
        system("./exe/grepfruit search -r 'NONEXISTENT' --json ./spec/test_dataset > /dev/null")
        expect($?.exitstatus).to eq(0)
      end
    end

    context "when --json flag is used with exclusions" do
      subject { `./exe/grepfruit search -r 'TODO' --json -e 'folder,bar.txt' ./spec/test_dataset` }

      it "includes exclusions in search metadata" do
        json = JSON.parse(subject)
        expect(json["search"]["exclusions"]).to contain_exactly("folder", "bar.txt")
      end
    end

    context "when --json flag is used with inclusions" do
      subject { `./exe/grepfruit search -r 'TODO' --json -i '*.py,*.txt' ./spec/test_dataset` }

      it "includes inclusions in search metadata" do
        json = JSON.parse(subject)
        expect(json["search"]["inclusions"]).to contain_exactly("*.py", "*.txt")
      end
    end

    context "when --json flag is used with both inclusions and exclusions" do
      subject { `./exe/grepfruit search -r 'TODO' --json -i '*.py,*.txt' -e 'ba*' ./spec/test_dataset` }

      it "includes both inclusions and exclusions in search metadata" do
        json = JSON.parse(subject)
        expect(json["search"]["inclusions"]).to contain_exactly("*.py", "*.txt")
        expect(json["search"]["exclusions"]).to contain_exactly("ba*")
      end
    end
  end

  describe "edge cases" do
    context "when searching non-existent directory" do
      subject { `./exe/grepfruit search -r 'TODO' ./nonexistent` }

      it { is_expected.to include("Error: Directory") }
      it { is_expected.to include("does not exist") }
    end

    context "when jobs count exceeds number of files" do
      subject { `./exe/grepfruit search -r 'TODO' -j 10 ./spec/test_dataset` }

      it { is_expected.to include("4 files checked") }
      it { is_expected.to include("16 matches found") }
    end
  end
end
