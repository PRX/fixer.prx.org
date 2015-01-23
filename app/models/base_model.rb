# encoding: utf-8

class BaseModel < ActiveRecord::Base
  self.abstract_class = true

  include FixerConstants

  # stub for now while async messaging gets sorted out
  def publish(*args)
  end
end
