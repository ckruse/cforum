# -*- coding: utf-8 -*-

require 'test_helper'

class VotePluginControllerTest < ActionController::TestCase
  test "should not vote because of anonymous" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise CForum::ForbiddenException do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s
      }
    end
  end

  test "should upvote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 1, message.upvotes
  end

  test "should upvote with badge" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user, admin: false)
    badge   = nil

    begin
      badge = FactoryGirl.create(:cf_badge, badge_type: RightsHelper::UPVOTE)
    rescue
      badge = CfBadge.where(badge_type: RightsHelper::UPVOTE).first
    end

    usr.badges_users.create(badge_id: badge.badge_id)
    assert usr.has_badge?(RightsHelper::UPVOTE)

    sign_in usr

    assert_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 1, message.upvotes
  end

  test "should not upvote without badge" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.upvotes
  end

  test "shouldnt downvote with zero or less points" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    CfScore.create!(user_id: usr.user_id, value: -10)

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)
  end

  test "should downvote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user)
    CfScore.create!(user_id: usr.user_id, value: 10)

    sign_in usr

    assert_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 1, message.downvotes
  end

  test "should downvote with badge" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user, admin: false)
    CfScore.create!(user_id: usr.user_id, value: 10)

    begin
      badge = FactoryGirl.create(:cf_badge, badge_type: RightsHelper::DOWNVOTE)
    rescue
      badge = CfBadge.where(badge_type: RightsHelper::DOWNVOTE).first
    end

    usr.badges_users.create(badge_id: badge.badge_id)
    assert usr.has_badge?(RightsHelper::DOWNVOTE)

    sign_in usr

    assert_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 1, message.downvotes
  end

  test "should not downvote without badge" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.downvotes
  end

  test "should downchange vote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, upvotes: 1)
    usr     = FactoryGirl.create(:cf_user)
    CfVote.create!(user_id: usr.user_id, message_id: message.message_id, vtype: CfVote::UPVOTE)
    CfScore.create!(user_id: usr.user_id, value: 10)

    sign_in usr

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.upvotes
    assert_equal 1, message.downvotes
  end

  test "should upchange vote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, downvotes: 1)
    usr     = FactoryGirl.create(:cf_user)
    CfVote.create!(user_id: usr.user_id, message_id: message.message_id, vtype: CfVote::DOWNVOTE)

    sign_in usr

    assert_no_difference 'CfVote.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 1, message.upvotes
    assert_equal 0, message.downvotes
  end


  test "vote up should score x points to bevoted user" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, downvotes: 1)
    usr     = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_difference 'CfScore.count' do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    s = CfScore.first
    assert_equal 10, s.value
  end

  test "vote down should score -x points to bevoted user and voter" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, downvotes: 1)
    usr     = FactoryGirl.create(:cf_user)
    CfScore.create!(user_id: usr.user_id, value: 10)

    sign_in usr

    assert_difference 'CfScore.count', 2 do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'down'
      }
    end

    s = CfScore.where(user_id: usr.user_id).sum(:value)
    assert_equal(9, s)

    s = CfScore.where(user_id: message.user_id).sum(:value)
    assert_equal(-1, s)
  end

  test "revote up should score x points to bevoted user and remove -score from voter" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, downvotes: 1)
    usr     = FactoryGirl.create(:cf_user)

    v = CfVote.create!(user_id: usr.user_id, message_id: message.message_id, vtype: CfVote::DOWNVOTE)
    CfScore.create!(user_id: usr.user_id, vote_id: v.vote_id, value: -1)
    CfScore.create!(user_id: message.user_id, vote_id: v.vote_id, value: -1)

    sign_in usr

    assert_difference 'CfScore.count', -1 do
      post :vote, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        type: 'up'
      }
    end

    s = CfScore.first
    assert_equal 10, s.value
  end


  test "should not upvote oneself" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = CfUser.find message.user_id

    sign_in usr

    assert_no_difference 'CfVote.count' do
      assert_no_difference 'CfScore.count' do
        post :vote, {
          curr_forum: forum.slug,
          year: '2012',
          mon: 'dec',
          day: '6',
          tid: 'obi-wan-kenobi',
          mid: message.message_id.to_s,
          type: 'up'
        }
      end
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.upvotes
  end

  test "should not downvote oneself" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    usr     = CfUser.find message.user_id

    sign_in usr

    assert_no_difference 'CfVote.count' do
      assert_no_difference 'CfScore.count' do
        post :vote, {
          curr_forum: forum.slug,
          year: '2012',
          mon: 'dec',
          day: '6',
          tid: 'obi-wan-kenobi',
          mid: message.message_id.to_s,
          type: 'down'
        }
      end
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.downvotes
  end

  test "should remove upvote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, upvotes: 1)
    user    = FactoryGirl.create(:cf_user)
    vote    = CfVote.create!(message_id: message.message_id, user_id: user.user_id, vtype: CfVote::UPVOTE)
    score   = CfScore.create!(vote_id: vote.vote_id, user_id: message.user_id, value: 10)

    sign_in user

    assert_difference 'CfVote.count', -1 do
      assert_difference 'CfScore.count', -1 do
        post :vote, {
          curr_forum: forum.slug,
          year: '2012',
          mon: 'dec',
          day: '6',
          tid: 'obi-wan-kenobi',
          mid: message.message_id.to_s,
          type: 'up'
        }
      end
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.upvotes
  end

  test "should remove downvote" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, downvotes: 1)
    user    = FactoryGirl.create(:cf_user)
    vote    = CfVote.create!(message_id: message.message_id, user_id: user.user_id, vtype: CfVote::DOWNVOTE)
    score   = CfScore.create!(vote_id: vote.vote_id, user_id: message.user_id, value: -1)

    sign_in user

    assert_difference 'CfVote.count', -1 do
      assert_difference 'CfScore.count', -1 do
        post :vote, {
          curr_forum: forum.slug,
          year: '2012',
          mon: 'dec',
          day: '6',
          tid: 'obi-wan-kenobi',
          mid: message.message_id.to_s,
          type: 'down'
        }
      end
    end

    assert_redirected_to cf_message_url(thread, message)

    message.reload
    assert_equal 0, message.downvotes
  end
end

# eof
