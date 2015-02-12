ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/spec'
require 'minitest/autorun'
require 'devise'

AudioMonster.logger = Logger.new('/dev/null')

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
end

class ActionController::TestCase
  include FactoryGirl::Syntax::Methods
  include Devise::TestHelpers
end

# MiniTest
class MiniTest::Unit::TestCase
  include FactoryGirl::Syntax::Methods
end

# MiniTest::Spec
class MiniTest::Spec
  include FactoryGirl::Syntax::Methods
end

def out_file(o)
  File.expand_path(File.dirname(__FILE__) + '/../tmp/' + o)
end

def in_file(i)
  File.expand_path(File.dirname(__FILE__) + '/fixtures/files/' + i)
end
