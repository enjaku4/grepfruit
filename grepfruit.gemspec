require_relative "lib/grepfruit/version"

Gem::Specification.new do |spec|
  spec.name = "grepfruit"
  spec.version = Grepfruit::VERSION
  spec.authors = ["enjaku4"]
  spec.email = ["enjaku4@icloud.com"]
  spec.homepage = "https://github.com/enjaku4/grepfruit"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "Text pattern search tool with CI-friendly exit codes"
  spec.description = "A pattern search tool with CI-friendly exit codes and colorized or JSON formatted output"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2", "< 3.5"

  spec.files = [
    "grepfruit.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + Dir.glob("{exe,lib}/**/*")

  spec.bindir = "exe"
  spec.executables = ["grepfruit"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-cli", "~> 1.1"
end
