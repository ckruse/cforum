require 'rails_helper'

RSpec.describe NotifyOpenCloseVoteJob, type: :job do
  let(:message) { create(:message) }
  let(:user) { create(:user_admin) }

  before(:each) do
    Setting.create!(user_id: user.user_id, options: { 'notify_on_open_close_vote' => 'yes' })
  end

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(message.message_id) }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(NotifyOpenCloseVoteJob)
    end

    it 'queues with default priority' do
      expect(NotifyOpenCloseVoteJob.new.queue_name).to eq('default')
    end
  end

  it 'notifies admins on flag' do
    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(1)
  end

  it "doesn't notify when disabled" do
    Setting.delete_all
    Setting.create!(user_id: user.user_id, options: { 'notify_on_open_close_vote' => 'no' })

    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(0)
  end

  it 'notifies moderators' do
    user.admin = false
    user.save!
    grp = Group.create!(name: 'foo')
    grp.users << user
    grp.forums_groups_permissions << ForumGroupPermission.new(permission: ForumGroupPermission::MODERATE,
                                                              forum_id: message.forum_id)

    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(1)
  end

  it 'notifies users with moderator badge' do
    user.destroy
    usr = create(:user_moderator)
    Setting.create!(user_id: usr.user_id, options: { 'notify_on_open_close_vote' => 'yes' })

    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(1)
  end

  it "doesn't notify normal users" do
    user.admin = false
    user.save!

    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(0)
  end

  it "doesn't notify users with moderator rights in different forum" do
    user.admin = false
    user.save!

    f = create(:forum)
    grp = Group.create!(name: 'foo')
    grp.users << user
    grp.forums_groups_permissions << ForumGroupPermission.new(permission: ForumGroupPermission::MODERATE,
                                                              forum_id: f.forum_id)

    expect do
      NotifyOpenCloseVoteJob.perform_now(message.message_id, 'created', 'close')
    end.to change(Notification, :count).by(0)
  end
end
