require 'rails_helper'

RSpec.describe NewMessageBadgesJob, type: :job do
  let(:user) { create(:user) }
  let(:thread) { create(:cf_thread) }
  let(:message) { create(:message, thread: thread, owner: user) }

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(thread.thread_id, message.message_id) }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(NewMessageBadgesJob)
    end

    it 'queues with default priority' do
      expect(NewMessageBadgesJob.new.queue_name).to eq('default')
    end
  end

  describe 'message count badges' do
    it 'successfully gives the chisel badge' do
      99.times { create(:message, owner: user) }
      create(:badge, slug: 'chisel', badge_type: 'custom')

      expect do
        NewMessageBadgesJob.perform_now(thread.thread_id, message.message_id)
      end.to change(BadgeUser, :count).by(1)
    end
  end

  describe 'teacher badge' do
    it 'gives the teacher badge' do
      message.upvotes = 1
      message.save!

      create(:badge, slug: 'teacher', badge_type: 'custom')
      user1 = create(:user)
      message1 = create(:message, owner: user1, parent: message, thread: thread)

      expect do
        NewMessageBadgesJob.perform_now(thread.thread_id, message1.message_id)
      end.to change(BadgeUser, :count).by(1)
    end

    it "it doesn't give the badge when parent author is oneself" do
      message.upvotes = 1
      message.save!

      create(:badge, slug: 'teacher', badge_type: 'custom')
      message1 = create(:message, owner: user, parent: message, thread: thread)

      expect do
        NewMessageBadgesJob.perform_now(thread.thread_id, message1.message_id)
      end.to change(BadgeUser, :count).by(0)
    end

    it "doesn't give the badge when parent voter is oneself" do
      message.upvotes = 1
      message.save!

      create(:badge, slug: 'teacher', badge_type: 'custom')
      user1 = create(:user)
      Vote.create!(message_id: message.message_id, user_id: user1.user_id, vtype: Vote::UPVOTE)
      message1 = create(:message, owner: user1, parent: message, thread: thread)

      expect do
        NewMessageBadgesJob.perform_now(thread.thread_id, message1.message_id)
      end.to change(BadgeUser, :count).by(0)
    end

    it "doesn't give the badge when parent is zero voted" do
      create(:badge, slug: 'teacher', badge_type: 'custom')
      user1 = create(:user)
      message1 = create(:message, owner: user1, parent: message, thread: thread)

      expect do
        NewMessageBadgesJob.perform_now(thread.thread_id, message1.message_id)
      end.to change(BadgeUser, :count).by(0)
    end
  end
end

# eof
