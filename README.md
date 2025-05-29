# Grepfruit: File Pattern Search Tool for Ruby

[![Gem Version](https://badge.fury.io/rb/grepfruit.svg)](http://badge.fury.io/rb/grepfruit)
[![Github Actions badge](https://github.com/brownboxdev/grepfruit/actions/workflows/ci.yml/badge.svg)](https://github.com/brownboxdev/grepfruit/actions/workflows/ci.yml)

Grepfruit is a Ruby gem for searching files within a directory for specified regular expression patterns, with intelligent exclusion options and colorized output for enhanced readability. Originally designed for CI/CD pipelines to search for `TODO` comments in Ruby on Rails applications, Grepfruit provides more user-friendly output than the standard `grep` command while maintaining the flexibility for diverse search scenarios.

**Key Features:**

- Regular expression search within files and directories
- Intelligent file and directory exclusion capabilities
- Colorized output for improved readability
- Hidden file and directory search support
- Configurable output truncation
- CI/CD pipeline friendly with meaningful exit codes
- Line-specific exclusion for precise control

## Table of Contents

**Gem Usage:**
  - [Installation](#installation)
  - [Basic Usage](#basic-usage)
  - [Command Line Options](#command-line-options)
  - [Usage Examples](#usage-examples)
  - [Exit Status](#exit-status)

**Community Resources:**
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Installation

Add Grepfruit to your Gemfile:

```rb
gem "grepfruit"
```

Install the gem:

```bash
bundle install
```

Or install it directly:

```bash
gem install grepfruit
```

## Basic Usage

Search for regex patterns within files in a specified directory:

```bash
grepfruit [options] PATH
```

If no PATH is specified, Grepfruit searches the current directory.

## Command Line Options

| Option | Description |
|--------|-------------|
| `-r, --regex REGEX` | Regex pattern to search for (required) |
| `-e, --exclude x,y,z` | Comma-separated list of files, directories, or lines to exclude |
| `-t, --truncate N` | Truncate search result output to N characters |
| `--search-hidden` | Include hidden files and directories in search |

## Usage Examples

### Basic Pattern Search

Search for `TODO` comments in the current directory:

```bash
grepfruit -r 'TODO'
```

### Excluding Directories

Search for `TODO` patterns while excluding common build and dependency directories:

```bash
grepfruit -r 'TODO' -e 'log,tmp,vendor,node_modules,assets'
```

### Multiple Pattern Search Excluding Both Directories and Files

Search for both `FIXME` and `TODO` comments in a specific directory:

```bash
grepfruit -r 'FIXME|TODO' -e 'bin,tmp/log,Gemfile.lock' dev/grepfruit
```

### Line-Specific Exclusion

Exclude specific lines from search results:

```bash
grepfruit -r 'FIXME|TODO' -e 'README.md:18'
```

### Output Truncation

Limit output length for cleaner results:

```bash
grepfruit -r 'FIXME|TODO' -t 50
```

### Including Hidden Files

Search hidden files and directories:

```bash
grepfruit -r 'FIXME|TODO' --search-hidden
```

## Exit Status

Grepfruit returns meaningful exit codes for CI/CD integration:

- **Exit code 0**: No matches found
- **Exit code 1**: Pattern matches were found

## Contributing

### Getting Help
Have a question or need assistance? Open a discussion in our [discussions section](https://github.com/brownboxdev/grepfruit/discussions) for:
- Usage questions
- Implementation guidance
- Feature suggestions

### Reporting Issues
Found a bug? Please [create an issue](https://github.com/brownboxdev/grepfruit/issues) with:
- A clear description of the problem
- Steps to reproduce the issue
- Your environment details (Ruby version, OS, etc.)

### Contributing Code
Ready to contribute? You can:
- Fix bugs by submitting pull requests
- Improve documentation
- Add new features (please discuss first in our [discussions section](https://github.com/brownboxdev/grepfruit/discussions))

Before contributing, please read the [contributing guidelines](https://github.com/brownboxdev/grepfruit/blob/master/CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/brownboxdev/grepfruit/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Grepfruit project is expected to follow the [code of conduct](https://github.com/brownboxdev/grepfruit/blob/master/CODE_OF_CONDUCT.md).
