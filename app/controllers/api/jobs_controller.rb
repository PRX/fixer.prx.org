module Api
  class JobsController < Api::ApiController

    before_filter :find_job, :only => [:retry, :update]

    # shouuld build paging into this, oy vey
    def index
      logger.debug "JobsController::index start!"
      @jobs = Job.where(application: current_application).order('id desc').limit(100)
      respond_with @jobs
    end

    def retry
      logger.debug "JobsController::retry job: #{params[:id]}"
      @job.retry(true)
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

    protected

    def find_job
      @job = Job.find(params[:id])
      raise 'Not your job!' unless @job.application == current_application
    end
  end
end
