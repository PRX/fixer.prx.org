# encoding: utf-8

require 'base_worker'

class TaskUpdateWorker < BaseWorker
  def perform(log)
    task_log = log['task_log']
    task = Task.find_by_id(task_log['task_id'])
    return unless task

    logged_at = task_log['logged_at'].blank? ? Time.now : Time.parse(task_log['logged_at'])
    task.log(task_log['status'], task_log['message'], task_log['info'], logged_at)
  end
end
