# encoding: utf-8

class Task < BaseModel
  enum status: STATUS_VALUES
end
