require 'test_helper'

class ImageProcessorTest < ActiveSupport::TestCase
  let(:processor) { ImageProcessor.new(logger: Logger.new('/dev/null')) }

  it 'defines supported tasks' do
    ImageProcessor.supported_tasks.first.must_equal 'resize'
  end

  describe "resize_image" do

    let(:msg) {
      {
        task: {
          id: 'guid1',
          task_type: 'resize',
          label: 'resize',
          job: { id: 'guid1', job_type: 'image', status: 'created', original: "file://#{in_file('test_pattern.jpg')}" },
          options: { size: '100x100' },
          result: 'file:///test/images/21/test_pattern_small.jpg'
        }
      }.with_indifferent_access
    }

    it "should resize a local file" do
      processor.on_message(msg)
      processor.result_details[:info][:file].must_match /JPEG/
    end

    it "should resize an http file" do
      msg[:task][:job][:original] = "http://s3.amazonaws.com/production.mediajoint.prx.org/public/comatose_files/4625/prx-logo_large.png"
      processor.on_message(msg)
      processor.result_details[:info][:file].must_match /PNG/
    end
  end
end
