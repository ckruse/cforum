require 'rails_helper'

RSpec.describe NotifyNewMessageJob, type: :job do
  include SubscriptionsHelper

  let(:thread) { create(:cf_thread) }
  let(:message) { create(:message, thread: thread) }
  let(:user) { create(:user) }

  describe 'Queuing of job' do
    subject(:thread_job) { described_class.perform_later(thread.thread_id, message.message_id, 'thread') }

    it 'queues the job' do
      expect { thread_job }.to have_enqueued_job(NotifyNewMessageJob)
    end

    it 'queues with default priority' do
      expect(NotifyNewMessageJob.new.queue_name).to eq('default')
    end
  end

  describe 'notifying mentions' do
    before(:each) do
      message.flags['mentions'] = [[user.username, user.user_id, false]]
      message.save!
    end

    it 'notifies on a mention' do
      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message.message_id, 'thread')
      end.to change(Notification, :count).by(1)
    end

    it "doesn't notify when disabled" do
      Setting.create!(user_id: user.user_id, options: { 'notify_on_mention' => 'no' })
      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message.message_id, 'thread')
      end.to change(Notification, :count).by(0)
    end
  end

  it 'notifies on new thread when enabled' do
    Setting.create!(user_id: user.user_id, options: { 'notify_on_new_thread' => 'yes' })
    expect do
      NotifyNewMessageJob.perform_now(thread.thread_id, message.message_id, 'thread')
    end.to change(Notification, :count).by(1)
  end

  it "doesn't on new thread when not enabled" do
    Setting.create!(user_id: user.user_id, options: { 'notify_on_new_thread' => 'no' })
    expect do
      NotifyNewMessageJob.perform_now(thread.thread_id, message.message_id, 'thread')
    end.to change(Notification, :count).by(0)
  end

  describe 'on new message' do
    let(:message1) { create(:message, parent: message, thread: message.thread) }
    subject(:job) { described_class.perform_later(thread.thread_id, message1.message_id, 'message') }

    it 'notifies when thread is subscribed' do
      subscribe_message(message, user)

      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message1.message_id, 'message')
      end.to change(Notification, :count).by(1)
    end

    it "doesn't notify when thread isn't subscribed" do
      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message1.message_id, 'message')
      end.to change(Notification, :count).by(0)
    end

    it "doesn't notify when different sub-thread is subscribed" do
      message2 = create(:message, parent: message, thread: thread)
      subscribe_message(message2, user)

      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message1.message_id, 'message')
      end.to change(Notification, :count).by(0)
    end

    it 'notifies only once' do
      message2 = create(:message, parent: message1, thread: thread)
      subscribe_message(message, user)
      subscribe_message(message1, user)

      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message2.message_id, 'message')
      end.to change(Notification, :count).by(1)
    end

    it 'notifies only for mention' do
      message1.flags['mentions'] = [[user.username, user.user_id, false]]
      message1.save!
      subscribe_message(message, user)

      expect do
        NotifyNewMessageJob.perform_now(thread.thread_id, message1.message_id, 'message')
      end.to change(Notification, :count).by(1)

      n = Notification.last
      expect(n.otype).to eq 'message:mention'
    end
  end
end
