require 'rails_helper'

describe 'deleting a thread' do
  let(:message) { create(:message) }
  let(:user) { create(:user) }
  let(:vote) do
    Vote.create!(user_id: user.user_id,
                 message_id: message.message_id,
                 vtype: Vote::UPVOTE)
  end

  before(:each) { login_as(user, scope: :user) }

  include CForum::Tools

  it "doesn't remove score when gotten via vote" do
    Score.create!(user_id: user.user_id,
                  vote_id: vote.vote_id,
                  value: 10)

    message.thread.destroy
    user.reload
    expect(user.score).to eq(10)
  end

  it "doesn't remove score when gotten via message" do
    Score.create!(user_id: user.user_id,
                  message_id: message.message_id,
                  value: 15)

    message.thread.destroy
    user.reload
    expect(user.score).to eq(15)
  end
end

# eof
