# -*- coding: utf-8 -*-

require 'test_helper'

class CfVoteTest < ActiveSupport::TestCase
  test "test validations" do
    m = FactoryGirl.create(:cf_message)
    u = FactoryGirl.create(:cf_user)
    v = CfVote.new

    assert !v.save

    v.message_id = m.message_id
    assert !v.save

    v.user_id = u.user_id
    assert !v.save

    v.vtype = CfVote::UPVOTE
    assert v.save

    v.vtype = 'lulu'
    assert !v.save
  end

  test "test user association" do
    v = FactoryGirl.create(:cf_vote)
    u = FactoryGirl.create(:cf_user)

    v1 = CfVote.find(v.vote_id)
    assert_not_nil v1.user

    v.user = u
    assert v.save

    v1 = CfVote.find(v.vote_id)
    assert_not_nil v1.user
    assert_equal u.user_id, v1.user.user_id
  end

  test "test message association" do
    v = FactoryGirl.create(:cf_vote)
    m = FactoryGirl.create(:cf_message)

    v1 = CfVote.find(v.vote_id)
    assert_not_nil v1.message

    v.message = m
    assert v.save

    v1 = CfVote.find(v.vote_id)
    assert_not_nil v1.message
    assert_equal m.message_id, v1.message.message_id
  end
end


# eof
