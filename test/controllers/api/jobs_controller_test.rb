require 'test_helper'

class Api::JobsControllerTest < ActionController::TestCase

  let(:user) { User.create!(email: 'test@prx.org', password: 'foobarpassword') }

  let(:application) do
    Doorkeeper::Application.create(
      name: 'test',
      owner: user,
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob'
    )
  end

  let(:token) do
    token = Minitest::Mock.new
    token.expect(:acceptable?, true, [Object])
    token.expect(:resource_owner_id, user.id)
    token.expect(:application, application)
    token
  end

  let(:job) do
    Job.create(job_type: 'audio', priority: 1, application_id: application.id)
  end

  let(:job_params) do
    {
      job_type: 'test',
      priority: 1,
      retry_max: 10,
      retry_delay: 300,
      original: 'file://this/aint/real.fake',
      original_format: 'mp3',
      tasks: [
        sequence: {
          tasks: [
            {
              task_type: 'echo',
              label: 'test0',
              options: { foo: 'bar' },
              call_back: 'http://cms.prx.dev/call_back'
            },
            {
              task_type: 'echo',
              label: 'test1',
              options: { foo: 'bar' },
              call_back: 'http://cms.prx.dev/call_back'
            }
          ]
        }
      ]
    }.with_indifferent_access
  end

  before {
    @controller.instance_eval do
      def doorkeeper_token=(t)
        @_doorkeeper_token = t
      end
    end
    @controller.doorkeeper_token = token
  }

  test "should create a job" do
    count = Job.count

    post :create, format: :json, job: job_params

    count.wont_equal Job.count(true)

    response.must_be :success?
    job = assigns(:job)
    job.wont_be_nil
    job.tasks.size.must_equal 1

    job.original_format.must_equal 'mp3'

    seq = job.tasks.first
    seq.must_be_instance_of Sequence
    seq.tasks.count.must_equal 2
    seq.tasks.each_with_index do |t, i|
      t.task_type.must_equal 'echo'
      t.label.must_equal "test#{i}"
      t.options[:foo].must_equal 'bar'
    end
  end

  test "should show job" do
    get :show, format: :json, id: job
    response.must_be :success?
  end

  test "should list jobs by page and application" do
    get :index, format: :json, page: 1, status: 'incomplete'
    response.must_be :success?
  end

  test "should update job" do
    patch :update, format: :json, id: job, job: { retry_max: 0 }
    response.must_be :success?
  end

  test "should retry a job" do
    post :retry, format: :json, id: job
    response.must_be :success?
  end
end
