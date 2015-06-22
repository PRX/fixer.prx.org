require 'test_helper'
require 'service_options'

class ServiceOptionsTest < ActiveSupport::TestCase

  it 'provides root path' do
    ServiceOptions.root.wont_be_nil
  end

  it 'can reload root' do
    ServiceOptions.root.wont_be_nil
    r = ServiceOptions.root
    ServiceOptions.root = nil
    ServiceOptions.root.must_equal r
  end

  it 'can set the root' do
    ServiceOptions.root = '/foo'
    ServiceOptions.root.must_equal '/foo'
    ServiceOptions.root = nil
  end

  it 'has yml file path to load' do
    ServiceOptions.file_path.must_match /services\.yml/
  end

  it 'can set yml file path' do
    ServiceOptions.file_path = 'foo.yml'
    ServiceOptions.file_path.must_equal 'foo.yml'
    ServiceOptions.file_path = nil
  end

  it 'gets provider for uri' do
    uri = URI.parse('s3://test.aws.amazon.com/test/test.mp3')
    provider = ServiceOptions.provider_abbr_for_uri(uri)
    provider.must_equal :aws
  end

  it 'can get service options by name' do
    opts = ServiceOptions.service_options('aws')
    opts['provider'].must_equal 'AWS'
    opts['path_style'].must_equal true
    opts['aws_access_key_id'].must_equal 'S3ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  end

  it 'can get service options by url' do
    opts = ServiceOptions.service_options(URI.parse('s3://test.aws.amazon.com/test/test.mp3'))
    opts['provider'].must_equal 'AWS'
    opts['path_style'].must_equal true
    opts['aws_access_key_id'].must_equal 'S3ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  end

  it 'can extract options from uri' do
    uri = URI.parse('s3://KEY:secret@test.aws.amazon.com/test/test.mp3')
    opts = ServiceOptions.storage_options_for_uri(uri)
    opts['aws_access_key_id'].must_equal 'KEY'
    opts['aws_secret_access_key'].must_equal 'secret'
  end

  it 'can parse service options from a file' do
    opts = ServiceOptions.parse_service_options
    opts['aws']['aws_access_key_id'].must_equal 'S3ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  end
end
