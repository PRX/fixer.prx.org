class FileProcessor < BaseProcessor

  task_types ['copy']

  def copy_file
    self.destination = source
    self.destination_format = source_format
    completed_with info_for(destination_format, destination)
  end

  def info_for(format, file)
    out, err = AudioMonster.run_command("file -b #{file.path}", nice: 'n', echo_return: false)
    { file: out.chomp }
  end
end
