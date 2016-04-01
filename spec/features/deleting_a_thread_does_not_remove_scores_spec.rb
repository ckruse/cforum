# -*- coding: utf-8 -*-

require "rails_helper"

include Warden::Test::Helpers
Warden.test_mode!

describe "deleting a thread" do
  let(:message) { create(:cf_message) }
  let(:user) { create(:user) }
  let(:vote) do
    CfVote.create!(user_id: user.user_id,
                   message_id: message.message_id,
                   vtype: CfVote::UPVOTE)
  end

  before(:each) { login_as(user, scope: :user) }

  include CForum::Tools

  it "doesn't remove score when gotten via vote" do
    CfScore.create!(user_id: user.user_id,
                    vote_id: vote.vote_id,
                    value: 10)

    message.thread.destroy
    expect(user.score).to eq(10)
  end

  it "doesn't remove score when gotten via message" do
    CfScore.create!(user_id: user.user_id,
                    message_id: message.message_id,
                    value: 15)

    message.thread.destroy
    expect(user.score).to eq(15)
  end

end

# eof
