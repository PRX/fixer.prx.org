module TasksHelper

  def format_log_info(task_log)
    out = ""
    if task_log.status == 'error'
      out += content_tag(:b, task_log.info['class'])
      out += content_tag(:pre, task_log.info['trace']) if task_log.info['trace']
    else
      out = if task_log.info.is_a?(Hash)
        hash_to_table(task_log.info)
      else
        content_tag(:span, task_log.info)
      end
    end
    out.html_safe
  end

end
