# encoding: utf-8

class BaseModel < ActiveRecord::Base

  self.include_root_in_json = true
  self.abstract_class = true

  include FixerConstants

  acts_as_scheduled
end
