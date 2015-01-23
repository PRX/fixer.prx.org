# encoding: utf-8

class TaskLog < BaseModel
  belongs_to :task

  has_one :web_hook, as: :informer

  serialize :info

  enum status: LOG_STATUS_VALUES

  validates_presence_of :status, :message
end
