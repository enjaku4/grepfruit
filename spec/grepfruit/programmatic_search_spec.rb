require "json"

RSpec.describe Grepfruit::ProgrammaticSearch do
  describe "Grepfruit.search" do
    it "returns a hash with search results" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/
      )

      expect(result).to be_a(Hash)
      expect(result).to have_key(:search)
      expect(result).to have_key(:summary)
      expect(result).to have_key(:matches)
    end

    it "includes search metadata" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/
      )

      expect(result[:search][:pattern]).to eq(/TODO/)
      expect(result[:search][:directory]).to eq(File.expand_path("./spec/test_dataset"))
    end

    it "includes correct summary counts" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/
      )

      expect(result[:summary][:files_checked]).to eq(4)
      expect(result[:summary][:files_with_matches]).to eq(4)
      expect(result[:summary][:total_matches]).to eq(16)
    end

    it "includes matches with file, line, and content" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/
      )

      expect(result[:matches]).to be_an(Array)
      expect(result[:matches].size).to eq(16)

      first_match = result[:matches].first
      expect(first_match).to have_key(:file)
      expect(first_match).to have_key(:line)
      expect(first_match).to have_key(:content)
    end

    it "respects exclude option" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        exclude: ["folder", "bar.txt"]
      )

      expect(result[:summary][:total_matches]).to be < 16
      expect(result[:matches].none? { |m| m[:file].include?("folder") || m[:file].include?("bar.txt") }).to be true
    end

    it "respects include option" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        include: ["*.py"]
      )

      expect(result[:summary][:files_checked]).to eq(1)
      expect(result[:summary][:total_matches]).to eq(4)
      expect(result[:matches].all? { |m| m[:file].end_with?(".py") }).to be true
    end

    it "respects truncate option" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        truncate: 15
      )

      result[:matches].each do |match|
        expect(match[:content].length).to be <= 18
      end

      expect(result[:matches].any? { |m| m[:content].end_with?("...") }).to be true
    end

    it "respects search_hidden option" do
      result_without_hidden = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        search_hidden: false
      )

      result_with_hidden = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        search_hidden: true
      )

      expect(result_with_hidden[:summary][:total_matches]).to be > result_without_hidden[:summary][:total_matches]
    end

    it "respects jobs option" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /TODO/,
        jobs: 1
      )

      expect(result[:summary][:total_matches]).to eq(16)
    end

    it "returns empty matches when no matches found" do
      result = Grepfruit.search(
        path: "./spec/test_dataset",
        regex: /NONEXISTENT/
      )

      expect(result[:matches]).to be_empty
      expect(result[:summary][:total_matches]).to eq(0)
      expect(result[:summary][:files_with_matches]).to eq(0)
    end

    describe "count mode" do
      it "returns result without matches key when count is true" do
        result = Grepfruit.search(
          path: "./spec/test_dataset",
          regex: /TODO/,
          count: true
        )

        expect(result).not_to have_key(:matches)
        expect(result[:summary][:total_matches]).to eq(16)
        expect(result[:summary][:files_checked]).to eq(4)
        expect(result[:summary][:files_with_matches]).to eq(4)
      end

      it "includes search metadata when count is true" do
        result = Grepfruit.search(
          path: "./spec/test_dataset",
          regex: /TODO/,
          count: true
        )

        expect(result[:search][:pattern]).to eq(/TODO/)
        expect(result[:search][:directory]).to eq(File.expand_path("./spec/test_dataset"))
      end

      it "returns result without matches key with count when no matches found" do
        result = Grepfruit.search(
          path: "./spec/test_dataset",
          regex: /NONEXISTENT/,
          count: true
        )

        expect(result).not_to have_key(:matches)
        expect(result[:summary][:total_matches]).to eq(0)
        expect(result[:summary][:files_with_matches]).to eq(0)
      end
    end

    describe "argument validation" do
      it "raises ArgumentError when regex is nil" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: nil)
        end.to raise_error(ArgumentError, "regex is required")
      end

      it "raises ArgumentError when regex is a string" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: "TODO")
        end.to raise_error(ArgumentError, "regex is required")
      end

      it "raises ArgumentError when jobs is less than 1" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, jobs: 0)
        end.to raise_error(ArgumentError, "jobs must be at least 1")
      end

      it "raises ArgumentError when path is not a string" do
        expect do
          Grepfruit.search(path: 123, regex: /TODO/)
        end.to raise_error(ArgumentError, "path must be a string")
      end

      it "raises ArgumentError when exclude is not an array" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, exclude: "foo")
        end.to raise_error(ArgumentError, "exclude must be an array")
      end

      it "raises ArgumentError when include is not an array" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, include: "foo")
        end.to raise_error(ArgumentError, "include must be an array")
      end

      it "raises ArgumentError when truncate is not a positive integer" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, truncate: -5)
        end.to raise_error(ArgumentError, "truncate must be a positive integer")
      end

      it "raises ArgumentError when truncate is zero" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, truncate: 0)
        end.to raise_error(ArgumentError, "truncate must be a positive integer")
      end

      it "raises ArgumentError when search_hidden is not a boolean" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, search_hidden: "yes")
        end.to raise_error(ArgumentError, "search_hidden must be a boolean")
      end

      it "raises ArgumentError when count is not a boolean" do
        expect do
          Grepfruit.search(path: "./spec/test_dataset", regex: /TODO/, count: "yes")
        end.to raise_error(ArgumentError, "count must be a boolean")
      end

      it "raises ArgumentError when directory does not exist" do
        expect do
          Grepfruit.search(path: "./nonexistent", regex: /TODO/)
        end.to raise_error(ArgumentError, /directory .* does not exist/)
      end
    end
  end
end
