# Grepfruit

[![Gem Version](https://badge.fury.io/rb/grepfruit.svg)](http://badge.fury.io/rb/grepfruit)
[![Github Actions badge](https://github.com/enjaku4/grepfruit/actions/workflows/ci.yml/badge.svg)](https://github.com/enjaku4/grepfruit/actions/workflows/ci.yml)

Grepfruit is a Ruby gem for searching files within a directory for a specified regular expression pattern, with options to exclude certain files or directories from the search and colorized output for better readability.

<img width="431" alt="Screenshot 2024-12-26 at 18 01 39" src="https://github.com/user-attachments/assets/e3fdb4f7-c4d9-4c8d-9a5a-228f2be55d52" />

Grepfruit was originally created to be used in CI/CD pipelines to search for `TODO` comments in Ruby on Rails applications and provide more user-friendly output than the standard `grep` command, but it is flexible enough to be used for other similar purposes as well.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "grepfruit"
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install grepfruit
```

## Usage

You can use Grepfruit from the command line to search for a regex pattern within files in a specified directory.

```shell
grepfruit [options] PATH
```

If no matches are found, Grepfruit returns exit status 0; otherwise, it returns exit status 1.

### Options

- `-r, --regex REGEX`: Regex pattern to search for (required).
- `-e, --exclude x,y,z`: Comma-separated list of files, directories, or lines to exclude from the search.
- `-t, --truncate N`: Truncate the output of the search results to N characters.
- `--search-hidden`: Search hidden files and directories.

### Examples

Search for the pattern `/TODO/` in the current directory, excluding `log`, `tmp`, `vendor`, `node_modules`, and `assets` directories:

```shell
grepfruit -r 'TODO' -e 'log,tmp,vendor,node_modules,assets'
```

Search for the pattern `/FIXME|TODO/` in `dev/grepfruit` directory, excluding `bin`, `tmp/log`, and `Gemfile.lock` files and directories:

```shell
grepfruit -r 'FIXME|TODO' -e 'bin,tmp/log,Gemfile.lock' dev/grepfruit
```

Search for the pattern `/FIXME|TODO/` in the current directory, excluding line 18 of `README.md`:

```shell
grepfruit -r 'FIXME|TODO' -e 'README.md:18'
```

Search for the pattern `/FIXME|TODO/` in the current directory, truncating the output of the search results to 50 characters:

```shell
grepfruit -r 'FIXME|TODO' -t 50
```

Search for the pattern `/FIXME|TODO/` in the current directory, including hidden files and directories:

```shell
grepfruit -r 'FIXME|TODO' --search-hidden
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
