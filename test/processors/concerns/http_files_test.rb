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
  let(:small_uri) { URI.parse('http://test.prx.org/test/small.txt') }

  it 'can download from http url' do
    fi = File.open(in_file('test_short.mp2'))
    stub_request(:get, http_uri.to_s).
      to_return(status: 200, headers: {}, body: fi)

    tmp = processor.http_download_file(http_uri)
    tmp.must_be_instance_of File
  end

  it 'can download a small file' do
    stub_request(:get, small_uri.to_s).
      to_return(status: 200, headers: {}, body: "so very small")

    tmp = processor.http_download_file(small_uri)
    tmp.must_be_instance_of File
  end

  it 'can download from https url' do
    fi = File.open(in_file('test_short.mp2'))
    stub_request(:get, https_uri.to_s).
      to_return(status: 200, headers: {}, body: fi)

    tmp = processor.https_download_file(https_uri)
    tmp.must_be_instance_of File
  end
end
