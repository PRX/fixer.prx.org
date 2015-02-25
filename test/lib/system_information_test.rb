require 'test_helper'

class SystemInformationTest < ActiveSupport::TestCase

  it 'provides public ip' do
    SystemInformation.public_ip_address
  end
end
