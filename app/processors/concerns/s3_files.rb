require 'audio_monster'

module S3Files

  def s3_upload_file(uri, file, options={})
    bucket = uri.host
    key = uri.path[1..-1]
    file_name = key.split("/").last

    default_options = {public: false, content_disposition: "attachment; filename=\"#{file_name}\""}
    opts = default_options.merge(options)
    opts[:key] = key
    opts[:body] = File.open(file)

    directory = storage_connection(uri).directories.get(bucket)
    s3_file = directory.files.create(opts)
  end

  def s3_download_file(uri)
    bucket = uri.host
    key = uri.path[1..-1]
    file_name = key.split("/").last

    directory = storage_connection(uri, {connection_options: {retry_limit: 0}}).directories.get(bucket)

    try_count = 0
    file_info = nil

    while !file_info && try_count < 10
      try_count += 1

      logger.info "s3_download_file: try: #{try_count}, checking for #{key} in #{bucket}"

      file_info = directory.files.head(key)
      sleep(1) if !file_info
    end

    if !file_info
      raise "File not found on s3: #{bucket}: #{key}"
    end

    try_count = 0
    file_downloaded = false
    temp_file = nil
    while !file_downloaded && try_count < 10
      try_count += 1
      begin

        if temp_file
          temp_file.close rescue nil
          temp_file.unlink rescue nil
        end

        temp_file = AudioMonster.create_temp_file(file_name)

        directory.files.get(key) do |chunk, remaining_bytes, total_bytes|
          temp_file.write(chunk)
        end

        temp_file.fsync()

        if (file_info.content_length != temp_file.size)
          raise "File incorrect size, s3 content_length: #{file_info.content_length}, local file size: #{temp_file.size}"
        end

        file_downloaded = true

      rescue StandardError => err
        logger.error "File failed to be retrieved: '#{file_name}': #{err.message}"
      end
      sleep(1)
    end

    if (file_info.content_length != temp_file.size)
      raise "File download failed, incorrect size, s3 content_length: #{file_info.content_length}, local file size: #{temp_file.size}"
    end

    if temp_file.size == 0
      raise "Zero length file from s3: #{bucket}: #{key}"
    end

    temp_file
  end
end
