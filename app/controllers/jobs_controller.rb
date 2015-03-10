# encoding: utf-8

class JobsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_job, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @jobs = Job.order('created_at DESC').page(params[:page])
    @jobs = @jobs.where(application_id: params[:app_id]) if params[:app_id]
    @jobs = @jobs.incomplete if params[:status] == 'incomplete'
    @jobs = @jobs.failed if params[:status] == 'failed'

    respond_with(@jobs)
  end

  def show
    respond_with(@job)
  end

  def new
    @job = Job.new
    respond_with(@job)
  end

  def edit
  end

  def create
    @job = Job.new(job_params)
    @job.save
    respond_with(@job)
  end

  def update
    @job.update(job_params)
    respond_with(@job)
  end

  def destroy
    @job.destroy
    respond_with(@job)
  end

  private
    def set_job
      @job = Job.find(params[:id])
    end

    def job_params
      params[:job]
    end
end
