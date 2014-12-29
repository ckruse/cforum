# -*- coding: utf-8 -*-

require 'test_helper'

class CfCloseVoteTest < ActiveSupport::TestCase
  test "user should have voted" do
    msg = FactoryGirl.create(:cf_message)
    u = FactoryGirl.create(:cf_user)

    v = CfCloseVote.create(message_id: msg.message_id, reason: 'off-topic')
    v.voters.create(user_id: u.user_id)

    assert v.has_voted?(u)
    assert v.has_voted?(u.user_id)
  end

  test "user shouldnt have voted" do
    msg = FactoryGirl.create(:cf_message)
    u = FactoryGirl.create(:cf_user)
    u1 = FactoryGirl.create(:cf_user)

    v = CfCloseVote.create(message_id: msg.message_id, reason: 'off-topic')
    v.voters.create(user_id: u.user_id)

    assert !v.has_voted?(u1)
    assert !v.has_voted?(u1.user_id)
  end
end


# eof
