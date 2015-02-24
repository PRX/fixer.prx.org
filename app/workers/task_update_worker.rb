# encoding: utf-8

require 'base_worker'

class TaskUpdateWorker < BaseWorker

  def perform(log)
    ActiveRecord::Base.connection_pool.with_connection do
      log = log.with_indifferent_access
      task_log = log[:task_log].with_indifferent_access
      task = Task.find_by_id(task_log[:task_id])
      return unless task

      task.log(task_log[:status], task_log[:message], task_log[:info], get_logged_at(task_log))
    end
  end

  def get_logged_at(task_log)
    if task_log[:logged_at].blank?
      Time.now
    elsif task_log[:logged_at].instance_of?(String)
      Time.parse(task_log[:logged_at])
    else
      task_log[:logged_at]
    end
  end
end
