# -*- coding: utf-8 -*-

require 'test_helper'

class CfScoreTest < ActiveSupport::TestCase
  test "test validations" do
    v = FactoryGirl.create(:cf_vote)
    u = FactoryGirl.create(:cf_user)
    s = CfScore.new

    assert !s.save

    s.vote_id = v.vote_id
    assert !s.save

    s.user_id = u.user_id
    assert !s.save

    s.value = 10
    assert s.save

    s.value = 'lulu'
    assert !s.save
  end

  test "test user association" do
    u = FactoryGirl.create(:cf_user)
    s = FactoryGirl.create(:cf_score)

    s1 = CfScore.find(s.score_id)
    assert_not_nil s1.user

    s.user = u
    assert s.save

    s1 = CfScore.find(s.score_id)
    assert_not_nil s1.user
    assert_equal u.user_id, s1.user.user_id
  end

  test "test vote association" do
    v = FactoryGirl.create(:cf_vote)
    s = FactoryGirl.create(:cf_score)

    s1 = CfScore.find(s.score_id)
    assert_not_nil s1.vote

    s.vote = v
    assert s.save

    s1 = CfScore.find(s.score_id)
    assert_not_nil s1.vote
    assert_equal v.vote_id, s1.vote.vote_id
  end
end


# eof
