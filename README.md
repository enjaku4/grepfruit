# Grepfruit: Enhanced File Pattern Search Tool

[![Gem Version](https://badge.fury.io/rb/grepfruit.svg)](http://badge.fury.io/rb/grepfruit)
[![Downloads](https://img.shields.io/gem/dt/grepfruit.svg)](https://rubygems.org/gems/grepfruit)
[![Github Actions badge](https://github.com/enjaku4/grepfruit/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/grepfruit/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/enjaku4/grepfruit.svg)](LICENSE)

Grepfruit is a Ruby gem for searching files within a directory for specified regular expression patterns. It provides exclusion and inclusion options with JSON-formatted or colorized output for enhanced readability.

Originally designed for CI/CD pipelines to search for `TODO` comments in Ruby applications, Grepfruit offers more user-friendly output than the standard `grep` command while maintaining flexibility for diverse search scenarios.

**Key Features:**

- Colorized output for improved readability
- JSON output format for programmatic integration
- CI/CD pipeline friendly exit codes

## Table of Contents

**Gem Usage:**
  - [Installation](#installation)
  - [Basic Usage](#basic-usage)
  - [Command Line Options](#command-line-options)
  - [Usage Examples](#usage-examples)
  - [Exit Status](#exit-status)

**Community Resources:**
  - [Getting Help and Contributing](#getting-help-and-contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Installation

Install the gem:

```bash
gem install grepfruit
```

## Basic Usage

Search for regex patterns within files in a specified directory:

```bash
grepfruit search [options] [PATH]
```

Or using shorthand `s` command:

```bash
grepfruit s [options] [PATH]
```

If no PATH is specified, Grepfruit searches the current directory.

## Command Line Options

| Option | Description |
|--------|-------------|
| `-r, --regex REGEX` | Regex pattern to search for (required) |
| `-e, --exclude x,y,z` | Comma-separated list of files, directories, or lines to exclude |
| `-i, --include x,y,z` | Comma-separated list of file patterns to include (only these files will be searched) |
| `-t, --truncate N` | Truncate search result output to N characters |
| `-j, --jobs N` | Number of parallel workers (default: number of CPU cores) |
| `--search-hidden` | Include hidden files and directories in search |
| `--json` | Output results in JSON format |

## Usage Examples

### Basic Pattern Search

Search for `TODO` comments in the current directory:

```bash
grepfruit search -r 'TODO'
```

### Excluding Directories

Search for `TODO` patterns while excluding common build and dependency directories:

```bash
grepfruit search -r 'TODO' -e 'log,tmp,vendor,node_modules,assets'
```

### Multiple Pattern Search Excluding Both Directories and Files

Search for both `FIXME` and `TODO` comments in a specific directory:

```bash
grepfruit search -r 'FIXME|TODO' -e 'bin,*.md,tmp/log,Gemfile.lock' dev/my_app
```

### Line-Specific Exclusion

Exclude specific lines from search results:

```bash
grepfruit search -r 'FIXME|TODO' -e 'README.md:18'
```

### Including Specific File Types

Search only in specific file types using patterns:

```bash
grepfruit search -r 'TODO' -i '*.rb,*.js'
grepfruit search -r 'FIXME' -i '*.py'
```

### Output Truncation

Limit output length for cleaner results:

```bash
grepfruit search -r 'FIXME|TODO' -t 50
```

### Including Hidden Files

Search hidden files and directories:

```bash
grepfruit search -r 'FIXME|TODO' --search-hidden
```

### JSON Output

Get structured JSON output:

```bash
grepfruit search -r 'TODO' -e 'node_modules' -i '*.rb,*.js' --json /path/to/search
```

This outputs a JSON response containing search metadata, summary statistics, and detailed match information:

```jsonc
{
  "search": {
    "pattern": "/TODO/",
    "directory": "/path/to/search",
    "exclusions": ["node_modules"],
    "inclusions": ["*.rb", "*.js"],
    "timestamp": "2025-01-16T10:30:00+00:00"
  },
  "summary": {
    "files_checked": 42,
    "files_with_matches": 8,
    "total_matches": 23
  },
  "matches": [
    {
      "file": "src/main.js",
      "line": 15,
      "content": "// TODO: Implement error handling"
    },
    // ...
  ]
}
```

### Parallel Processing

Control the number of parallel workers:

```bash
grepfruit search -r 'TODO' -j 8  # Use 8 parallel workers
grepfruit search -r 'TODO' -j 1  # Sequential processing
```

## Exit Status

Grepfruit returns meaningful exit codes for CI/CD integration:

- **Exit code 0**: No matches found (ideal for quality gates - code is clean)
- **Exit code 1**: Pattern matches were found (CI should fail - issues detected)

## Getting Help and Contributing

### Getting Help
Have a question or need assistance? Open a discussion in our [discussions section](https://github.com/enjaku4/grepfruit/discussions) for:
- Usage questions
- Implementation guidance
- Feature suggestions

### Reporting Issues
Found a bug? Please [create an issue](https://github.com/enjaku4/grepfruit/issues) with:
- A clear description of the problem
- Steps to reproduce the issue
- Your environment details (Ruby version, OS, etc.)

### Contributing Code
Ready to contribute? You can:
- Fix bugs by submitting pull requests
- Improve documentation
- Add new features (please discuss first in our [discussions section](https://github.com/enjaku4/grepfruit/discussions))

Before contributing, please read the [contributing guidelines](https://github.com/enjaku4/grepfruit/blob/master/CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/enjaku4/grepfruit/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Grepfruit project is expected to follow the [code of conduct](https://github.com/enjaku4/grepfruit/blob/master/CODE_OF_CONDUCT.md).
