require 'test_helper'
require 'concerns/http_files'

class HttpFilesTest < ActiveSupport::TestCase

  class TestProcessor
    include HttpFiles

    def logger
      @logger = Logger.new('/dev/null')
    end
  end

  let(:processor) { TestProcessor.new }

  before {
    WebMock.disable_net_connect!
  }

  after {
    WebMock.allow_net_connect!
  }

  let(:http_uri) { URI.parse('http://test.prx.org/test/file.mp2') }
  let(:https_uri) { URI.parse('https://test.prx.org/test/file.mp2') }

  it 'can download from http url' do

    stub_request(:get, http_uri.to_s).
      with(headers: {'Host'=>'test.prx.org:80'}).
      to_return(status: 200, headers: {}, body: File.open(in_file('test_short.mp2')))

    tmp = processor.http_download_file(http_uri)
    tmp.must_be_instance_of File
  end

  it 'can download from https url' do
    stub_request(:get, https_uri.to_s).
      with(:headers => {'Host'=>'test.prx.org:443'}).
      to_return(status: 200, headers: {}, body: File.open(in_file('test_short.mp2')))

    tmp = processor.https_download_file(https_uri)
    tmp.must_be_instance_of File
  end
end
