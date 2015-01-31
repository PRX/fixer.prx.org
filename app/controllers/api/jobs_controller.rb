module Api
  class JobsController < Api::ApiController

    before_action :set_job, only: [:show, :retry, :update]

    def index
      @jobs = Job.where(application_id: current_application.id)
      respond_with @jobs
    end

    def show
      respond_with @job
    end

    def update
      tasks = params[:job].delete('tasks') || []
      @job.update_attributes!(params[:job])
      respond_with @job
    end

    def create
      @job = Job.create_from_message(params, current_application)
      respond_with @job
    end

    def retry
      @job.retry(true)
      respond_with @job
    end

    protected

    def set_job
      @job = Job.find(params[:id])
      raise 'Not your job!' unless @job.application == current_application
    end
  end
end
