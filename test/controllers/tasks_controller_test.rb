require 'test_helper'

class TasksControllerTest < ActionController::TestCase

  setup do
    @user = User.create!(email: 'test@prx.org', password: 'foobarpassword')
    @application = Doorkeeper::Application.create(name: 'test', owner: @user, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')
    @job = Job.create(job_type: 'audio', priority: 1, application_id: @application.id)
    @task = Task.create!(job_id: @job.id)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in @user
  end

  test "should get index" do
    get :index, job_id: @job.id
    assert_response :success
    assert_not_nil assigns(:tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  # test "should create task" do
  #   assert_difference('Task.count') do
  #     post :create, task: {  }
  #   end

  #   assert_redirected_to task_path(assigns(:task))
  # end

  test "should show task" do
    get :show, id: @task
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @task
    assert_response :success
  end

  test "should update task" do
    patch :update, id: @task, task: {  }
    assert_redirected_to task_path(assigns(:task))
  end

  test "should destroy task" do
    assert_difference('Task.count', -1) do
      delete :destroy, id: @task
    end

    assert_redirected_to tasks_path
  end
end
