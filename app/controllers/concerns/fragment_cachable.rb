module FragmentCachable
  extend ActiveSupport::Concern

  private

  # Used to work out where to cache fragments. We add an extra path to the
  # URL using the first three digits of the info request id, because we can't
  # have more than 32,000 entries in one directory on an ext3 filesystem.
  def foi_fragment_cache_part_path(param)
    path = url_for(param.merge(only_path: true))
    id = param['id'] || param[:id]
    first_three_digits = id.to_s[0..2]
    path = path.sub("/request/", "/request/" + first_three_digits + "/")
    return path
  end

  def foi_fragment_cache_path(param)
    path = File.join(Rails.root, 'cache', 'views', foi_fragment_cache_part_path(param))
    max_file_length = 255 - 35 # we subtract 35 because tempfile
    # adds on a variable number of
    # characters
    return File.join(File.split(path).map { |x| x[0...max_file_length] })
  end

  def foi_fragment_cache_exists?(key_path)
    return File.exist?(key_path)
  end

  def foi_fragment_cache_read(key_path)
    logger.info "Reading from fragment cache #{key_path}"
    return File.read(key_path)
  end

  def foi_fragment_cache_write(key_path, content)
    FileUtils.mkdir_p(File.dirname(key_path))
    logger.info "Writing to fragment cache #{key_path}"
    File.atomic_write(key_path) do |f|
      f.write(content)
    end
    FileUtils.chmod 0644, key_path
  end
end
