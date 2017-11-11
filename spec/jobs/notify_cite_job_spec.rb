require 'rails_helper'

RSpec.describe NotifyCiteJob, type: :job do
  let(:user) { create(:user) }
  let(:cite) { create(:cite) }

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(cite.cite_id, 'create') }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(NotifyCiteJob)
    end

    it 'queues with default priority' do
      expect(NotifyCiteJob.new.queue_name).to eq('default')
    end
  end

  it 'notifies user on creation' do
    user
    expect do
      NotifyCiteJob.perform_now(cite.cite_id, 'create')
    end.to change(Notification, :count).by(1)
  end

  it 'destroys unread notifications on deletion' do
    user
    NotifyCiteJob.perform_now(cite.cite_id, 'create')

    expect do
      NotifyCiteJob.perform_now(cite.cite_id, 'destroy')
    end.to change(Notification, :count).by(-1)
  end

  it 'notifies user on deletion' do
    user
    NotifyCiteJob.perform_now(cite.cite_id, 'create')
    Notification.update_all(is_read: true)

    expect do
      NotifyCiteJob.perform_now(cite.cite_id, 'destroy')
    end.to change(Notification, :count).by(1)
  end

  it "doesn't notify when disabled" do
    Setting.create!(user_id: user.user_id, options: { 'notify_on_cite' => 'no' })
    expect do
      NotifyCiteJob.perform_now(cite.cite_id, 'create')
    end.to change(Notification, :count).by(0)
  end
end
