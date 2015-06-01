# encoding: utf-8

class TasksController < ApplicationController
  before_action :authenticate_user!

  before_action :set_task, only: [:show, :edit, :update, :destroy, :inform]
  before_action :set_job, only: [:index]

  respond_to :html

  # GET /job/tasks?job_id=1
  def index
    @tasks = @job.tasks
  end

  # GET /tasks/1
  def show
  end

  # GET /tasks/new
  def new
    @task = Task.new
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to @task, notice: 'Task was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      redirect_to @task, notice: 'Task was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy
    redirect_to job_url(@task.job_id), notice: 'Task was successfully destroyed.'
  end

  # POST /tasks/1/inform
  def inform
    @task.send_call_back(true)
    redirect_to @task, notice: 'WebHook sent.'
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def set_job
    @job = Job.find(params[:job_id])
  end

  def option_keys
    if params[:task] && params[:task][:options]
      task[:options].keys
    end || []
  end

  def task_params
    task_attributes = [:task_type, :result, :label, :call_back, options: option_keys]
    task_attributes << { sequence: { tasks: task_attributes.dup } }
    params.require(:task).permit(task_attributes)
  end
end
