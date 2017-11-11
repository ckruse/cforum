require 'rails_helper'

RSpec.describe VoteBadgeDistributorJob, type: :job do
  let(:user) { create(:user) }
  let(:message) { create(:message, owner: user) }
  let(:vote) do
    Vote.create!(user_id: user.user_id,
                 message_id: message.message_id,
                 vtype: Vote::UPVOTE)
  end

  before(:each) do
    Score.create!(vote_id: vote.vote_id,
                  value: 10,
                  user_id: user.user_id)

    create(:badge, slug: 'enthusiast', badge_type: 'custom')
    create(:badge, slug: 'critic', badge_type: 'custom')
    create(:badge, slug: 'controverse', badge_type: 'custom')
    create(:badge, slug: 'voter', badge_type: 'custom')
    create(:badge, slug: 'donee', badge_type: 'custom')
    create(:badge, slug: 'nice_answer', badge_type: 'custom')
    create(:badge, slug: 'good_answer', badge_type: 'custom')
    create(:badge, slug: 'great_answer', badge_type: 'custom')
    create(:badge, slug: 'superb_answer', badge_type: 'custom')
  end

  describe 'Queuing of job' do
    subject(:job) { described_class.perform_later(vote.vote_id, message.message_id, 'voted') }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(VoteBadgeDistributorJob)
    end

    it 'queues with default priority' do
      expect(VoteBadgeDistributorJob.new.queue_name).to eq('default')
    end
  end

  describe 'voter badges' do
    it 'successfully grats the voter badge' do
      VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
      user.reload
      expect(user.badges).to include(Badge.find_by!(slug: 'voter'))
    end

    it 'successfully grants the enthusiast badge' do
      VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
      user.reload
      expect(user.badges).to include(Badge.find_by!(slug: 'enthusiast'))
    end

    it 'successfully grants the critic badge' do
      vote.vtype = Vote::DOWNVOTE
      vote.save!

      VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
      user.reload
      expect(user.badges).to include(Badge.find_by!(slug: 'critic'))
    end

    it 'successfully grants the controverse badge' do
      message.upvotes = 5
      message.downvotes = 5
      message.save!

      VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
      user.reload
      expect(user.badges).to include(Badge.find_by!(slug: 'controverse'))
    end
  end

  it 'successfully grants the donee badge' do
    message.upvotes = 1
    message.save!

    VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
    user.reload
    expect(user.badges).to include(Badge.find_by!(slug: 'donee'))
  end

  it 'successfully grants the nice answer badge' do
    message.upvotes = 5
    message.save!

    VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
    user.reload
    expect(user.badges).to include(Badge.find_by!(slug: 'nice_answer'))
  end

  it 'successfully grants the good answer badge' do
    message.upvotes = 15
    message.save!

    VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
    user.reload
    expect(user.badges).to include(Badge.find_by!(slug: 'good_answer'))
  end

  it 'successfully grants the great answer badge' do
    message.upvotes = 25
    message.save!

    VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
    user.reload
    expect(user.badges).to include(Badge.find_by!(slug: 'great_answer'))
  end

  it 'successfully grants the superb answer badge' do
    message.upvotes = 25
    message.save!

    VoteBadgeDistributorJob.perform_now(vote.vote_id, message.message_id, 'voted')
    user.reload
    expect(user.badges).to include(Badge.find_by!(slug: 'superb_answer'))
  end

  it "doesn't fail if vote doesn't exist" do
    expect { VoteBadgeDistributorJob.perform_now(123, nil, 'voted') }.to_not raise_error
  end

  it "doesn't fail if message doesn't exist" do
    expect { VoteBadgeDistributorJob.perform_now(nil, 123, 'voted') }.to_not raise_error
  end
end

# eof
