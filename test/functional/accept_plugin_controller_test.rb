# -*- coding: utf-8 -*-

require 'test_helper'

class AcceptPluginControllerTest < ActionController::TestCase
  test "should not accept as anonymous" do
    forum    = FactoryGirl.create(:cf_write_forum)
    thread   = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message  = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: thread, parent_id: message.message_id)

    assert_no_difference 'CfScore.count' do
      post :accept, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message1.message_id.to_s
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))

    message1.reload
    assert message1.flags['accepted'] != 'yes'
  end

  test "should accept as OP owner" do
    forum    = FactoryGirl.create(:cf_write_forum)
    thread   = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message  = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: thread, parent_id: message.message_id)

    sign_in message.owner

    assert_difference 'CfScore.count' do
      post :accept, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message1.message_id.to_s
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))

    message1.reload
    assert message1.flags['accepted'] == 'yes'
  end

  test "should unaccept on duplicate" do
    forum    = FactoryGirl.create(:cf_write_forum)
    thread   = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message  = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: thread, parent_id: message.message_id, flags: {'accepted' => 'yes'})

    CfScore.create!(message_id: message1.message_id, value: 10, user_id: message1.user_id)

    sign_in message.owner

    assert_equal 'yes', message1.flags['accepted']

    assert_difference 'CfScore.count', -1 do
      post :accept, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message1.message_id.to_s
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))

    message1.reload
    assert message1.flags['accepted'] != 'yes'
  end

  test "should remove accept on first when accepting second" do
    forum    = FactoryGirl.create(:cf_write_forum)
    thread   = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message  = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: thread, parent_id: message.message_id, flags: {'accepted' => 'yes'})
    message2 = FactoryGirl.create(:cf_message, forum: forum, thread: thread, parent_id: message.message_id, flags: {'accepted' => 'no'})

    CfScore.create!(message_id: message1.message_id, value: 10, user_id: message1.user_id)

    sign_in message.owner

    assert_no_difference 'CfScore.count' do
      post :accept, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message2.message_id.to_s
      }
    end

    message1.reload
    assert message1.flags['accepted'] != 'yes'
    message2.reload
    assert message2.flags['accepted'] == 'yes'

    score = CfScore.find_by_message_id_and_user_id(message1.message_id, message1.user_id)
    assert_nil score
    score = CfScore.find_by_message_id_and_user_id(message2.message_id, message2.user_id)
    assert_not_nil score

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end
end

# eof
