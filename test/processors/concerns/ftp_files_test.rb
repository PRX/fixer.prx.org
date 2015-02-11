require 'test_helper'
require 'concerns/ftp_files'

class FtpFilesTest < ActiveSupport::TestCase

  class TestProcessor
    include FtpFiles

    def logger
      @logger = Logger.new('/dev/null')
    end
  end

  let(:processor) { TestProcessor.new }

  it 'can upload to ftp site' do
    uri = URI.parse('ftp://log%20in:pass%20word@host:55/remote%20directory/nested/file%20name.test')

    mock = Minitest::Mock.new

    mock.expect(:override_local=, true, [true])
    mock.expect(:passive=, true, [true])
    mock.expect(:binary=, true, [true])
    mock.expect(:noop, true)

    mock.expect(:connect, true, ['host', 55])
    mock.expect(:login, true, ['log in', 'pass word'])
    mock.expect(:mkdir, true, ['remote directory/nested'])
    mock.expect(:chdir, true, ['remote directory/nested'])
    mock.expect(:put, true, ['file', 'file name.test'])

    mock.expect(:closed?, true)
    mock.expect(:close, true)

    Net::FTP.stub :new, mock do
      processor.ftp_upload_file(uri, Struct.new(:path).new('file'), { no_md5: true, no_retry: true })
    end
  end

  it 'can download from ftp site' do
    uri = URI.parse('ftp://log%20in:pass%20word@host:55/remote%20directory/nested/file%20name.test')

    mock = Minitest::Mock.new

    mock.expect(:override_local=, true, [true])
    mock.expect(:passive=, true, [true])
    mock.expect(:binary=, true, [true])
    mock.expect(:noop, true)

    mock.expect(:connect, true, ['host', 55])
    mock.expect(:login, true, ['log in', 'pass word'])
    mock.expect(:chdir, true, ['remote directory/nested'])
    mock.expect(:get, true, ['file name.test', String])

    mock.expect(:closed?, true)
    mock.expect(:close, true)

    Net::FTP.stub :new, mock do
      processor.ftp_download_file(uri, { retry_max: 1 })
    end
  end

end
