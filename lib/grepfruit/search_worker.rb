module Grepfruit
  module SearchWorker
    FIND_ERRORS = [Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG, Errno::EINVAL].freeze
    REGEX_SYNTAX = /[\\^$.|?*+()\[\]{}]/
    # The most of a file a worker reads into memory at once
    CHUNK_SIZE = 256 * 1024

    module_function

    def run(port, regex, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden, count, relative_paths)
      # A Regexp shared between Ractors stops scaling past a few cores, so each worker matches with its own copy
      regex = Regexp.new(regex, timeout: regex.timeout)
      literal = literal_bytes(regex)

      loop do
        task, payload = Ractor.receive
        break if task == :quit

        result =
          if task == :list
            list_directory(payload, relative_base, encoding, excluded_paths, excluded_lines, inclusions, search_hidden)
          else
            search_files(payload, regex, literal, count, relative_paths)
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

    # A pattern with no regex syntax and no flags matches exactly the lines that contain it as plain text, so a file
    # without its bytes has no matches. Line breaks and encoding conversion would make a file's bytes differ from its lines.
    def literal_bytes(regex)
      text = regex.source
      return if regex.options.anybits?(Regexp::IGNORECASE | Regexp::EXTENDED | Regexp::NOENCODING) || text.match?(REGEX_SYNTAX) || text.match?(/[\r\n]/)
      return unless Encoding.default_internal.nil? && (text.ascii_only? || text.encoding == Encoding.default_external)

      text.b
    end

    def search_files(entries, regex, literal, count, relative_paths)
      entries.map do |file_path, rel_path, file_excluded_lines|
        search_file(file_path, relative_paths ? rel_path : file_path, file_excluded_lines, regex, literal, count)
      end
    end

    # Opening the file decides readability instead of File.readable?, whose extra access(2) call cost a fifth of the search
    def search_file(file_path, match_path, file_excluded_lines, regex, literal, count)
      File.open(file_path) { search_open_file(_1, match_path, file_excluded_lines, regex, literal, count) }
    rescue Errno::EACCES
      nil
    rescue Errno::ENOENT, Errno::EISDIR
      [[], 0]
    end

    # Small files read faster whole; larger ones stream, so memory stays bounded whatever their size
    def search_open_file(file, match_path, file_excluded_lines, regex, literal, count)
      if file.size > CHUNK_SIZE
        return [[], 0] if literal && !contains_bytes?(file, literal)

        lines = file.each_line
      else
        content = file.read
        return [[], 0] if literal && !content.b.include?(literal)

        lines = content.each_line
      end

      search_lines(lines, match_path, file_excluded_lines, regex, count)
    rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR
      [[], 0]
    end

    # Reads into one reused buffer, and checks occurrences across chunk edges in a small separate string,
    # so memory stays at one chunk however large the file. Leaves the file at its start, ready to be read as lines.
    def contains_bytes?(file, bytes)
      overlap = bytes.bytesize - 1
      chunk, tail = "".b, "".b

      while file.read(CHUNK_SIZE, chunk)
        return true if chunk.include?(bytes) || (tail + chunk.byteslice(0, overlap)).include?(bytes)

        tail = last_bytes(chunk.bytesize >= overlap ? chunk : tail + chunk, overlap)
      end

      false
    ensure
      file.rewind
    end

    def last_bytes(string, count)
      string.byteslice([string.bytesize - count, 0].max, count)
    end

    def search_lines(lines, match_path, file_excluded_lines, regex, count)
      file_results, match_count, line_num = [], 0, 0

      lines.each do |line|
        line_num += 1
        next unless line.valid_encoding? && line.match?(regex)

        next if file_excluded_lines.include?(line_num)

        file_results << [match_path, line_num, line] unless count
        match_count += 1
      end

      [file_results, match_count]
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
