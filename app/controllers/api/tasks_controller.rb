module Api
  class TasksController < Api::ApiController
    def update
      @task = Task.find(params[:id])
      task_updates = params[:task].reject{|key, value| !['status'].include?(key)}
      @task.update!(task_updates)
      respond_with @task
    end
  end
end
