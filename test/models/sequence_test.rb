require 'test_helper'

class SequenceTest < ActiveSupport::TestCase

  let(:job) { Job.create(job_type: 'audio', application_id: 1, original: "file://#{in_file('test_long.wav')}") }

  let(:sequence) do
    Sequence.create(job: job,
                    call_back: 'http://development.prx.org:3001/audio_files/21/preview',
                    result: 's3://development.tcf.prx.org/public/audio_files/21/preview.mp3')
  end

  it 'uses uuid for id' do
    sequence.id.length.must_equal 36
  end

  it 'uses an enum for the status' do
    sequence.must_be :created?
  end

  it 'can be created as a child of a job, with callback and result' do
    sequence.must_be :valid?
    sequence.call_back.must_equal 'http://development.prx.org:3001/audio_files/21/preview'
    sequence.result.must_equal 's3://development.tcf.prx.org/public/audio_files/21/preview.mp3'
  end

  it 'has a sorted list of tasks' do
    t1 = sequence.tasks.create!(task_type: 'cut',
                                label: 'cut the mp2',
                                options: { length: '30', fade: 5 } )

    t2 = sequence.tasks.create!(task_type: 'transcode',
                                label: 'now make it an mp3',
                                options: { format: 'mp3', sample_rate: '44100', bit_rate: '128' } )

    t1.must_be :valid?
    t2.must_be :valid?

    t1.must_be :persisted?
    t2.must_be :persisted?

    t1.position.must_equal 1
    t2.position.must_equal 2
  end
end
