module Api
  class JobsController < Api::ApiController

    before_action :find_job, only: [:show, :retry, :update]

    def index
      logger.debug "JobsController::index start!"
      @jobs = Job.where(application_id: current_application.id)
      respond_with @jobs
    end

    def show
      logger.debug "JobsController::show start!"
      respond_with @job
    end

    def update
      logger.debug "JobsController::update job: #{params[:id]}"
      tasks = params[:job].delete('tasks') || []
      @job.update_attributes!(params[:job])
      respond_with @job
    end

    def create
      logger.debug "JobsController::create start: job: #{params[:job].inspect}"
      @job = Job.create_from_message(params, current_application)
      respond_with @job
    end

    def retry
      logger.debug "JobsController::retry job: #{params[:id]}"
      @job.retry(true)
      respond_with @job
    end

    protected

    def find_job
      @job = Job.find(params[:id])
      raise 'Not your job!' unless @job.application == current_application
    end
  end
end
