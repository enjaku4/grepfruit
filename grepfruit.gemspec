require_relative "lib/grepfruit/version"

Gem::Specification.new do |spec|
  spec.name = "grepfruit"
  spec.version = Grepfruit::VERSION
  spec.authors = ["enjaku4"]
  spec.homepage = "https://github.com/enjaku4/grepfruit"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "A Ruby gem for searching text patterns in files with colorized output"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0", "< 3.4"

  spec.files = [
    "grepfruit.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + `git ls-files | grep -E '^(lib|exe)'`.split("\n")

  spec.bindir = "exe"
  spec.executables = ["grepfruit"]
  spec.require_paths = ["lib"]
end
