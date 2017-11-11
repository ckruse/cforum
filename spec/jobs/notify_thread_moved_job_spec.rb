require 'rails_helper'

RSpec.describe NotifyThreadMovedJob, type: :job do
  let(:user) { create(:user_admin) }
  let(:message) { create(:message, owner: user) }
  let(:old_forum) { create(:forum) }

  before(:each) do
    Setting.create!(user_id: user.user_id, options: { 'notify_on_move' => 'yes' })
  end

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(message.thread_id, old_forum.forum_id, message.forum_id) }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(NotifyThreadMovedJob)
    end

    it 'queues with default priority' do
      expect(NotifyThreadMovedJob.new.queue_name).to eq('default')
    end
  end

  it 'notifies owner on move' do
    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(1)
  end

  it 'notifies subscriber on move' do
    u1 = create(:user)
    Setting.create!(user_id: u1.user_id, options: { 'notify_on_move' => 'yes' })
    Subscription.create!(user_id: u1.user_id, message_id: message.message_id)

    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(2)
  end

  it 'notifies interested user on move' do
    u1 = create(:user)
    Setting.create!(user_id: u1.user_id, options: { 'notify_on_move' => 'yes' })
    InterestingMessage.create!(user_id: u1.user_id, message_id: message.message_id)

    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(2)
  end

  it "doesn't notify owner when disabled" do
    Setting.delete_all
    Setting.create!(user_id: user.user_id, options: { 'notify_on_move' => 'no' })

    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(0)
  end

  it "doesn't notify interested user on move when disabled" do
    u1 = create(:user)
    Setting.create!(user_id: u1.user_id, options: { 'notify_on_move' => 'no' })
    InterestingMessage.create!(user_id: u1.user_id, message_id: message.message_id)

    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(1)
  end

  it "doesn't notify subscriber on move when disabled" do
    u1 = create(:user)
    Setting.create!(user_id: u1.user_id, options: { 'notify_on_move' => 'no' })
    Subscription.create!(user_id: u1.user_id, message_id: message.message_id)

    expect do
      NotifyThreadMovedJob.perform_now(message.thread_id, old_forum.forum_id, message.forum_id)
    end.to change(Notification, :count).by(1)
  end
end
