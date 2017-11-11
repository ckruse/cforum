require 'rails_helper'

RSpec.describe ResizeImageJob, type: :job do
  let(:medium) { create(:medium) }

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(medium.medium_id) }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(ResizeImageJob)
    end

    it 'queues with default priority' do
      expect(ResizeImageJob.new.queue_name).to eq('default')
    end
  end

  it 'creates image dirs' do
    obj = object_double('FileUtils', mkdir_p: nil).as_stubbed_const
    ResizeImageJob.perform_now(medium.medium_id)

    expect(obj).to have_received(:mkdir_p).with(Medium.path)
    expect(obj).to have_received(:mkdir_p).with(Medium.thumb_path)
    expect(obj).to have_received(:mkdir_p).with(Medium.medium_path)
  end
end

# eof
