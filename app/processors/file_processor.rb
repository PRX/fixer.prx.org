# encoding: utf-8

require 'base_processor'

class FileProcessor < BaseProcessor

  task_types ['copy', 'delete']

  def copy_file
    self.destination = source
    self.destination_format = source_format
    completed_with file_info
  end

  def delete_file
    delete_url = original_url
    delete_file_by_url(delete_url, options)
    completed_with file_info(source)
  end

  def original_url
    URI.parse(job['original']) if job['original']
  end
end
