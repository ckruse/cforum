require 'rails_helper'

RSpec.describe NotifyFlaggedJob, type: :job do
  let(:message) { create(:message) }
  let(:user) { create(:user_admin) }

  before(:each) do
    message.flags_will_change!
    message.flags['flagged'] = 'off-topic'
    message.save!

    Setting.create!(user_id: user.user_id, options: { 'notify_on_flagged' => 'yes' })
  end

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(message.message_id) }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(NotifyFlaggedJob)
    end

    it 'queues with default priority' do
      expect(NotifyFlaggedJob.new.queue_name).to eq('default')
    end
  end

  it 'notifies admins on flag' do
    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(1)
  end

  it "doesn't notify when disabled" do
    Setting.delete_all
    Setting.create!(user_id: user.user_id, options: { 'notify_on_flagged' => 'no' })

    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(0)
  end

  it 'notifies moderators' do
    user.admin = false
    user.save!
    grp = Group.create!(name: 'foo')
    grp.users << user
    grp.forums_groups_permissions << ForumGroupPermission.new(permission: ForumGroupPermission::ACCESS_MODERATE,
                                                              forum_id: message.forum_id)

    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(1)
  end

  it 'notifies users with moderator badge' do
    user.destroy
    usr = create(:user_moderator)
    Setting.create!(user_id: usr.user_id, options: { 'notify_on_flagged' => 'yes' })

    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(1)
  end

  it "doesn't notify normal users" do
    user.admin = false
    user.save!

    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(0)
  end

  it "doesn't notify users with moderator rights in different forum" do
    user.admin = false
    user.save!

    f = create(:forum)
    grp = Group.create!(name: 'foo')
    grp.users << user
    grp.forums_groups_permissions << ForumGroupPermission.new(permission: ForumGroupPermission::ACCESS_MODERATE,
                                                              forum_id: f.forum_id)

    expect {
      NotifyFlaggedJob.perform_now(message.message_id)
    }.to change(Notification, :count).by(0)
  end
end
