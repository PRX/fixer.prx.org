require 'audio_monster'
require 'net/ftp'
require 'timeout'

module FtpFiles

  def ftp_download_file(uri, options={})
    retry_max = options[:retry_max] || 6
    retry_wait = options[:retry_wait] || 10
    retry_count = 0
    result = false
    ftp = nil
    err = nil

    remote_host       = URI.decode(uri.host || '')
    remote_port       = uri.port.to_i || 21
    remote_file_name  = File.basename(URI.decode(uri.path))
    remote_directory  = File.dirname(URI.decode(uri.path))
    remote_user       = URI.decode(uri.user) if uri.user
    remote_password   = URI.decode(uri.password) if uri.password

    passive = options[:passive].nil? ? true : !!options[:passive]

    local_file = nil

    while (!result && (retry_count < retry_max)) do

      if local_file
        local_file.close rescue nil
        local_file.unlink rescue nil
      end

      local_file = AudioMonster.create_temp_file(remote_file_name)

      begin
        ftp = Net::FTP.new()
        ftp.binary = options[:binary].nil? ? true : !!options[:binary]
        ftp.passive = passive

        # connect, auth, and change dir should take no more than 1 min
        begin
          Timeout.timeout(60) do
            ftp.connect(remote_host, remote_port)
            ftp.login(remote_user, remote_password) if uri.userinfo
            ftp.chdir(remote_directory)
          end
        rescue StandardError => err
          logger.error "Connection to FTP server address failed #{uri.inspect}: #{err.message}"
          raise err
        end

        # get the file, catch errors and log when they occur
        # give each file 1/2 hour to get ftp'd down
        begin
          Timeout.timeout(1800) do
            ftp.get(remote_file_name, local_file.path)
          end
        rescue StandardError => err
          #need to do something to retry this - use new a13g func for this.
          logger.error "File failed to be retrieved: '#{remote_file_name}'"
          raise err
        end

        result = true
      rescue StandardError => err
        if passive && ((retry_count +1) >= retry_max)
          passive = false
          retry_count = 0
          logger.error "ftp_file retry in active mode: retrycount(#{retry_count}): error: #{err.message}"
        else
          #need to do something to retry this - use new a13g func for this.
          logger.error "ftp_file retrycount(#{retry_count}, #{retry_max}): error: #{err.message}"
          retry_count = retry_count + 1
          sleep(retry_wait) if retry_count <= retry_max
        end
      ensure
        ftp.close if ftp && !ftp.closed?
      end
    end

    if !result
      if err
        raise err
      else
        raise "FTP download failed, no more retries:'#{uri.to_s}'"
      end
    end

    local_file
  end

    def ftp_upload_file(uri, local_file, options={})
    no_retry = !!options[:no_retry]

    retry_max = no_retry ? 1 : (options[:retry_max] || 6)
    retry_wait = no_retry ? 0 : (options[:retry_wait] || 10)
    retry_count = 0
    result = false

    remote_host       = URI.decode(uri.host) if uri.host
    remote_port       = uri.port
    remote_path       = URI.decode(uri.path)
    remote_file_name  = File.basename(remote_path)
    remote_directory  = File.dirname(remote_path)
    remote_user       = URI.decode(uri.user) if uri.user
    remote_password   = URI.decode(uri.password) if uri.password

    md5_file = create_md5_digest(local_file.path) unless options[:no_md5]

    # capture the last error so we can log it
    err = nil

    # this may be turned to active on error
    passive = options[:passive].nil? ? true : !!options[:passive]

    # this may be turned to 0 on error
    keep_alive = options[:keep_alive].to_i

    while (!result && (retry_count < retry_max)) do
      ftp = Net::FTP.new()

      begin
        # this makes active mode on ec2 work by sending the public ip
        ftp.local_host = SystemInformation.public_ip_address if SystemInformation.public_ip_address

        # this works around badly specified masquerade ip for pasv
        ftp.override_local = true

        ftp.passive = passive
        ftp.binary = options[:binary].nil? ? true : !!options[:binary]

        # connect, auth, and change dir should take no more than 1 min
        # connected = false
        # connect_retry_count = 0
        # connect_retry_max = [3, retry_max].max
        # while (!connected) do
          begin
            Timeout.timeout(60) do
              ftp.connect(remote_host, remote_port)
              ftp.login(remote_user, remote_password) if uri.userinfo
            end
            # connected = true
          rescue StandardError => err
            logger.error "Connection to FTP server address failed #{uri.inspect}: #{err.message}"
            raise err # unless connect_retry_count < connect_retry_max
            # sleep(retry_wait)
            # connect_retry_count += 1
          end
        # end

        # if there is a remote dir that is not "."
        if remote_directory && remote_directory != '.'
          begin
            Timeout.timeout(60) do
              begin
                ftp.mkdir(remote_directory)
              rescue StandardError => err
                logger.warn("ftp mkdir #{remote_directory} failed: #{err.message}")
              end
              ftp.chdir(remote_directory)
            end
          rescue StandardError => err
            logger.error "Failed to make or change to FTP remote dir: #{remote_directory}, address: #{uri.inspect}: #{err.message}"
            logger.error "#{err.class.name} : #{err.inspect}"
            raise err
          end
        end

        # deliver the file, catch errors and log when they occur
        # give each file 1/2 hour to get ftp'd
        begin
          Timeout.timeout(1800) do
            logger.debug "ftp deliver #{local_file.path} as #{remote_file_name}:"

            last_noop = Time.now.to_i

            # local_file_size = File.size(local_file)
            bytes_uploaded = 0

            ftp.put(local_file.path, remote_file_name) do |chunk|
              bytes_uploaded += chunk.size

              if (keep_alive > 0) && ((last_noop + keep_alive) < Time.now.to_i)
                last_noop = Time.now.to_i

                # this is to act as a keep alive - wbur needed it for remix delivery
                begin
                  ftp.noop
                rescue StandardError=>err
                  # if they don't support this, and throw an error just keep going.
                  logger.warn("ftp NOOP caused an error, turning it off and trying again: #{err.message}")
                  retry_count = [(retry_count - 1), 0].max
                  keep_alive = 0
                  raise err
                end

                # logger.debug "ftp put to #{remote_host}, #{bytes_uploaded} of #{local_file_size} bytes, (#{bytes_uploaded * 100 / local_file_size}%)."
              end

            end

            logger.debug "ftp delivered #{local_file.path} as #{remote_file_name}"

            unless options[:no_md5]
              ftp.puttextfile(md5_file.path, remote_file_name + '.md5')
              logger.debug "ftp delivered #{md5_file.path} as #{remote_file_name}.md5"
            end
          end
        rescue StandardError=>ex
          #need to do something to retry this - use new a13g func for this.
          logger.error "File '#{local_file.path}' failed to be delivered as '#{remote_file_name}'\n#{ex.message}\n\t" + ex.backtrace[0,3].join("\n\t")
          raise ex
        end

        result = true
      rescue StandardError=>err
        # this can happen when this should be an active, not passive mode
        # only try half the retry attempts in this case
        if passive && ((retry_count + 1) >= ((retry_max||0)/2).to_i)
          passive = false
          retry_count = 0
          logger.error "ftp_file retry in active mode: retrycount(#{retry_count}): error: #{err.message}"
        else
          #need to do something to retry this - use new a13g func for this.
          logger.error "ftp_file retrycount(#{retry_count}): error: #{err.message}"
          retry_count = retry_count + 1
          sleep(retry_wait)
        end
      ensure
        begin
          ftp.close if ftp && !ftp.closed?
        rescue Object=>ex
          logger.error "ftp_file failed to close ftp: #{ex.class.name}\n#{ex.message}\n\t" + ex.backtrace[0,3].join("\n\t")
        end
      end
    end

    if !result
      if err
        raise err
      else
        raise "FTP fail, no more retries: from '#{local_file}' to '#{uri.to_s}'"
      end
    end

  ensure
    if md5_file
      md5_file.close rescue nil
      md5_file.unlink rescue nil
    end
  end

  def create_md5_digest(file)
    digest = Digest::MD5.hexdigest(File.read(file))
    logger.debug "digest = #{digest}"

    md5_digest_file = AudioMonster.create_temp_file(file + '.md5', false)
    md5_digest_file.write digest
    md5_digest_file.fsync
    md5_digest_file.close

    raise "Zero length md5 digest file: #{md5_digest_file.path}" if File.size(md5_digest_file.path) == 0
    md5_digest_file
  end

end
