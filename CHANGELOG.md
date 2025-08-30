## v3.1.2

- Corrected usage of `dry-cli` gem for flag handling
- Relaxed dependency versions

## v3.1.1

- Fixed JSON timestamp to reflect result generation time
- Minor optimization

## v3.1.0

- Added --include option to specify files to include in the search
- Both --exclude and --include options can now accept wildcard patterns

## v3.0.0

- Dropped support for Ruby 3.1
- Optimized search algorithm for better performance
- Changed the interface: now use `grepfruit search` instead of just `grepfruit` to perform searches
- Added JSON output format for search results
- Added parallel processing and --jobs option to control worker count

## v2.0.4

- Fixed path resolution bug where searching in relative directories such as `.`, `./`, or `..` did not work correctly

## v2.0.3

- Updated gemspec metadata to include the correct homepage URL

## v2.0.2

- Replaced `git ls-files` with `Dir.glob` in gemspec for improved portability and compatibility

## v2.0.1

- Enhanced output to include the number of files with matches

## v2.0.0

- Added support for Ruby 3.4
- Dropped support for Ruby 3.0

## v1.1.2

- Refactored code significantly for improved search efficiency and easier maintenance
- Enhanced search result output for better readability

## v1.1.1

- Added test dataset to make testing and development easier
- Updated gemspec file to include missing metadata

## v1.1.0

- Added `--truncate` option to truncate the output of the search results
- Added the ability to exclude lines from the search results

## v1.0.0

- Removed default values for `--exclude` and `--regex` options
- Made `--regex` option required
- Fixed an error that was raised when a symbolic link was encountered during the search

## v0.2.0

- Added `--search-hidden` option to search hidden files and directories

## v0.1.0

- Initial release
