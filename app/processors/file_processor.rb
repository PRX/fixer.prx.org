# encoding: utf-8

require 'base_processor'

class FileProcessor < BaseProcessor

  task_types ['copy']

  def copy_file
    self.destination = source
    self.destination_format = source_format
    completed_with file_info
  end
end
