require_relative "lib/grepfruit/version"

Gem::Specification.new do |spec|
  spec.name = "grepfruit"
  spec.version = Grepfruit::VERSION
  spec.authors = ["enjaku4"]
  spec.email = ["contact@brownbox.dev"]
  spec.homepage = "https://github.com/enjaku4/grepfruit"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata["mailing_list_uri"] = "#{spec.homepage}/discussions"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "Tool for searching regex patterns in files"
  spec.description = "A tool for searching regex patterns in files with a programmatic API and a CI/CD-friendly CLI"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2", "< 4.1"

  spec.files = [
    "grepfruit.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + Dir.glob("{exe,lib}/**/*")

  spec.bindir = "exe"
  spec.executables = ["grepfruit"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-cli", "~> 1.1"
end
