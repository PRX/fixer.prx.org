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
      job_attributes = job_params
      tasks = job_attributes.delete(:tasks) || []
      @job.update_attributes!(job_attributes)
      respond_with @job
    end

    def create
      @job = Job.create_from_message(job_params, current_application)
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

    def job_params
      option_keys = params[:job][:tasks].map{ |t| (t[:options] || {}).keys }.flatten
      logger.error "option_keys: #{option_keys.inspect}"
      task_attributes = [:task_type, :result, :label, :call_back, options: option_keys]
      job_attrs = [:job_type, :original, :status, :call_back, :priority, :retry_max, :retry_delay, tasks: task_attributes]
      params.require(:job).permit(job_attrs)
    end
  end
end
