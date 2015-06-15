# encoding: utf-8

require 'base_processor'
require 'uri'
require 'mini_magick'

class ImageProcessor < BaseProcessor
  task_types ['resize', 'rotate', 'format']

  attr_accessor :magick_image

  def resize_image
    magick_image.resize options['size'] || '100x100'
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    magick_image.write(task_tmp.path)
    self.destination = task_tmp

    completed_with file_info
  end

  def rotate_image
    magick_image.rotate options['rotation'] || '-90>'
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    magick_image.write(task_tmp.path)
    self.destination = task_tmp

    completed_with file_info
  end

  def format_image
    format = options['format'] || 'png'
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    magick_image.write(task_tmp.path)
    self.destination = task_tmp
    self.destination_format = format

    completed_with file_info
  end

  def prepare_task
    logger.error "prepare_task: #{source.path}: #{source.inspect}"
    self.magick_image = MiniMagick::Image.open(source.path)
  end
end
