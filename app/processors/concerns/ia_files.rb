# encoding: utf-8

require 'audio_monster'

module IaFiles

  def ia_delete_file(uri, options = {})
    bucket = uri.host
    key = uri.path[1..-1]
    opts = { key: key }
    directory = storage_connection(uri).directories.get(bucket)
    file = directory.files.new(opts)
    file.destroy
  end

  # refactor this and s3 upload - tres similar except default options
  def ia_upload_file(uri, file, options={})
    bucket = uri.host
    key = uri.path[1..-1]
    file_name = key.split("/").last

    dir_opts = default_ia_options.merge(options).merge({:key => bucket})
    directory = storage_connection(uri).directories.new(dir_opts)

    file_opts = default_ia_options.merge(options).merge({
      content_disposition: "attachment; filename=\"#{file_name}\"",
      key: key,
      body: File.open(file)
    })

    ia_file = directory.files.create(file_opts)
  end

  def default_ia_options
    opts = {}
    opts[:collections] = ['test_collection'] if (ENV['RAILS_ENV'] != 'production')
    opts[:ignore_preexisting_bucket] = 0
    opts[:interactive_priority] = 1
    opts[:auto_make_bucket] = 1
    opts
  end

  # refactor this and s3 download - tres similar
  def ia_download_file(uri)
    bucket = uri.host
    key = uri.path[1..-1]
    file_name = key.split("/").last

    directory = storage_connection(uri).directories.get(bucket)

    try_count = 0
    file_exists = false
    while !file_exists && try_count < 10
      logger.error "ia_download_file: try: #{try_count}, checking for #{key} in #{bucket}"

      try_count += 1
      file_exists = directory.files.head(key)

      if !file_exists
        sleep(1)
      end
    end

    if !file_exists
      raise "File not found on ia: #{bucket}: #{key}"
    end

    temp_file = AudioMonster.create_temp_file(file_name)
    file = directory.files.get(key)
    temp_file.write(file.body)
    temp_file.fsync()

    if File.size(temp_file) == 0
      raise "Zero length file from ia: #{bucket}: #{key}"
    end

    temp_file
  end

end
