# encoding: utf-8

class JobsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_job, only: [:show, :edit, :update, :destroy, :retry, :inform]

  respond_to :html

  # GET /jobs
  def index
    @jobs = Job.order('created_at DESC').page(params[:page]).per(params[:per_page])
    @jobs = @jobs.where(application_id: params[:app_id]) if params[:app_id]
    @jobs = @jobs.incomplete if params[:status] == 'incomplete'
    @jobs = @jobs.failed if params[:status] == 'failed'
    @jobs
  end

  # GET /jobs/1
  def show
  end

  # GET /jobs/new
  def new
    @job = Job.new
  end

  # GET /jobs/1/edit
  def edit
  end

  # POST /jobs
  def create
    @job = Job.new(job_params)
    if @job.save
      redirect_to @job, notice: 'Job was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /jobs/1
  def update
    if @job.update(job_params)
      redirect_to @job, notice: 'Job was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /jobs/1
  def destroy
    @job.destroy
    redirect_to jobs_url, notice: 'Job was successfully destroyed.'
  end

  # POST /jobs/1/retry
  def retry
    @job.retry(true)
    redirect_to @job, notice: 'Job will be retried.'
  end

  # POST /jobs/1/inform
  def inform
    @job.send_call_back(true)
    redirect_to @job, notice: 'WebHook sent.'
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    job_attrs = [:job_type, :original, :status, :call_back, :priority, :retry_max, :retry_delay]
    params.require(:job).permit(job_attrs)
  end
end
