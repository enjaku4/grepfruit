module Grepfruit
  module SearchWorker
    FIND_ERRORS = [Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG, Errno::EINVAL].freeze

    module_function

    def run(port, regex, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden, count, relative_paths)
      # A Regexp shared between Ractors stops scaling past a few cores, so each worker matches with its own copy
      regex = Regexp.new(regex, timeout: regex.timeout)

      loop do
        task, payload = Ractor.receive
        break if task == :quit

        result =
          if task == :list
            list_directory(payload, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden)
          else
            search_files(payload, regex, count, relative_paths)
          end

        RactorCompat.yield_result(port, result)
      end
    end

    def list_directory(dir, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden)
      subdirs, files = [], []

      begin
        names = Dir.children(dir, encoding:)
      rescue *FIND_ERRORS
        return [subdirs, files]
      end

      names.each do |name|
        file_path = File.join(dir, name)

        begin
          stat = File.lstat(file_path)
        rescue *FIND_ERRORS
          next
        end

        is_file = stat.file? || (stat.symlink? && File.file?(file_path))
        rel_path = file_path.delete_prefix(relative_base)

        next if excluded_path?(is_file, rel_path, name, excluded_paths, inclusions, search_hidden)

        if stat.directory?
          subdirs << file_path
        elsif is_file
          files << file_entry(file_path, rel_path, name, excluded_lines)
        end
      end

      [subdirs, files]
    end

    def file_entry(file_path, rel_path, name, excluded_lines)
      [file_path, rel_path, excluded_lines.filter_map { |pattern, line| line if matches_pattern?(pattern, rel_path, name) }]
    end

    def search_files(entries, regex, count, relative_paths)
      entries.map do |file_path, rel_path, file_excluded_lines|
        search_file(file_path, relative_paths ? rel_path : file_path, file_excluded_lines, regex, count)
      end
    end

    # Opening the file decides readability instead of File.readable?, whose extra access(2) call cost a fifth of the search
    def search_file(file_path, match_path, file_excluded_lines, regex, count)
      file = File.open(file_path)
    rescue Errno::EACCES
      nil
    rescue Errno::ENOENT, Errno::EISDIR
      [[], 0]
    else
      search_lines(file, match_path, file_excluded_lines, regex, count)
    end

    def search_lines(file, match_path, file_excluded_lines, regex, count)
      file_results, match_count = [], 0

      file.each_line.with_index do |line, line_num|
        next unless line.valid_encoding? && line.match?(regex)

        next if file_excluded_lines.include?(line_num + 1)

        file_results << [match_path, line_num + 1, line] unless count
        match_count += 1
      end

      [file_results, match_count]
    rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR
      [[], 0]
    ensure
      file.close
    end

    def excluded_path?(is_file, rel_path, name, excluded_paths, inclusions, search_hidden)
      (is_file && inclusions.any? && !matches_any?(inclusions, rel_path, name)) ||
        matches_any?(excluded_paths, rel_path, name) ||
        (!search_hidden && name.start_with?("."))
    end

    def matches_any?(patterns, rel_path, name)
      patterns.any? { matches_pattern?(_1, rel_path, name) }
    end

    def matches_pattern?(pattern, rel_path, name)
      File.fnmatch?(pattern, rel_path, File::FNM_PATHNAME | File::FNM_DOTMATCH) || File.fnmatch?(pattern, name, File::FNM_DOTMATCH)
    end
  end
end
