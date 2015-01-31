require 'test_helper'

class JobsControllerTest < ActionController::TestCase
  setup do
    @user = User.create!(email: 'test@prx.org', password: 'foobarpassword')
    @application = Doorkeeper::Application.create(name: 'test', owner: @user, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')
    @job = Job.create(job_type: 'audio', priority: 1, application_id: @application.id)

    @request.env["devise.mapping"] = Devise.mappings[:user]
    # user.confirm! # or set a confirmed_at inside the factory. Only necessary if you are using the "confirmable" module
    sign_in @user
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  # TODO: add actual params for this
  # test "should create job" do
  #   assert_difference('Job.count') do
  #     post :create, job: {  }
  #   end

  #   assert_redirected_to job_path(assigns(:job))
  # end

  test "should show job" do
    get :show, id: @job
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @job
    assert_response :success
  end

  test "should update job" do
    patch :update, id: @job, job: {  }
    assert_redirected_to job_path(assigns(:job))
  end

  test "should destroy job" do
    assert_difference('Job.count', -1) do
      delete :destroy, id: @job
    end

    assert_redirected_to jobs_path
  end
end
