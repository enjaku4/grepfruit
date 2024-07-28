# Grepfruit

[![Gem Version](https://badge.fury.io/rb/grepfruit.svg)](http://badge.fury.io/rb/grepfruit)
[![Github Actions badge](https://github.com/enjaku4/grepfruit/actions/workflows/main.yml/badge.svg)](https://github.com/enjaku4/grepfruit/actions/workflows/main.yml)

Grepfruit is a Ruby gem for searching files within a directory for a specified regular expression pattern, with options to exclude certain files or directories from the search and colorized output for better readability.

<img width="416" alt="Screenshot 2024-07-28 at 03 52 37" src="https://github.com/user-attachments/assets/95b26b81-dcc1-430b-ac44-641251cb84b6">

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grepfruit'
```

And then execute:

```shell
bundle install
```

## Usage

You can use Grepfruit from the command line to search for a regex pattern within files in a specified directory.

```shell
grepfruit [options] PATH
```

### Options

- `-r, --regex REGEX: Regex pattern to search for. Defaults to /TODO/.
- `-e, --exclude x,y,z: Comma-separated list of files and directories to exclude from the search. Defaults to log, tmp, vendor, node_modules, assets.

### Examples

Search for the pattern `TODO` in the current directory, excluding the default directories:

```shell
grepfruit
```

Search for a custom pattern in another directory, while specifying files and directories to exclude:

```shell
grepfruit -r 'FIXME|TODO' -e 'bin,log,Rakefile,Gemfile.lock' /path/to/directory
```

## Problems?

Facing a problem or want to suggest an enhancement?

- **Open a Discussion**: If you have a question, experience difficulties using the gem, or have a suggestion for improvements, feel free to use the Discussions section.

Encountered a bug?

- **Create an Issue**: If you've identified a bug, please create an issue. Be sure to provide detailed information about the problem, including the steps to reproduce it.
- **Contribute a Solution**: Found a fix for the issue? Feel free to create a pull request with your changes.

## Contributing

Before creating an issue or a pull request, please read the [contributing guidelines](https://github.com/enjaku4/grepfruit/blob/master/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/enjaku4/grepfruit/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Grepfruit project is expected to follow the [code of conduct](https://github.com/enjaku4/grepfruit/blob/master/CODE_OF_CONDUCT.md).
