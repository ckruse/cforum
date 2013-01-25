# -*- coding: utf-8 -*-

require 'test_helper'

class MarkReadTest < ActionController::TestCase
  def setup
    @controller = CfMessagesController.new
  end

  test "should not mark read because of anonymous" do
    message = FactoryGirl.create(:cf_message)

    assert_no_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    } do
      get :show, to_params_hash(message)
    end

    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:message)
  end

  test "should message mark read" do
    message = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)

    sign_in user

    assert_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    } do
      get :show, to_params_hash(message)
    end

    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:message).attribs
    assert assigns(:message).attribs['classes'].include?('visited')
  end

  test "should thread mark read" do
    message = FactoryGirl.create(:cf_message)
    message1 = FactoryGirl.create(:cf_message, thread: message.thread, parent_id: message.message_id)
    user = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'standard_view' => 'nested-view'
      }
    )

    sign_in user

    assert_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    }, 2 do
      get :show, to_params_hash(message)
    end

    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:message)

    assigns(:thread).messages.each do |m|
      assert_not_nil m.attribs
      assert m.attribs['classes'].include?('visited')
    end
  end

  test "should not mark messages read in threadlist" do
    @controller = CfThreadsController.new

    m1 = FactoryGirl.create(:cf_message)
    thread = FactoryGirl.create(:cf_thread, forum: m1.forum)
    m2 = FactoryGirl.create(:cf_message, thread: thread)
    user = FactoryGirl.create(:cf_user)

    CfMessage.connection.execute "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", " + m1.message_id.to_s + ")"
    CfMessage.connection.execute "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", " + m2.message_id.to_s + ")"

    assert_no_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    } do
      get :index, curr_forum: m1.forum.slug
    end

    assert_response :success
    assert_not_nil assigns(:threads)

    assigns(:threads).each do |t|
      assert !t.messages[0].attribs['classes'].include?('visited')
    end
  end

  test "should mark messages read in threadlist" do
    @controller = CfThreadsController.new

    m1 = FactoryGirl.create(:cf_message)
    thread = FactoryGirl.create(:cf_thread, forum: m1.forum)
    m2 = FactoryGirl.create(:cf_message, thread: thread)
    user = FactoryGirl.create(:cf_user)

    sign_in user

    CfMessage.connection.execute "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", " + m1.message_id.to_s + ")"
    CfMessage.connection.execute "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", " + m2.message_id.to_s + ")"

    assert_no_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    } do
      get :index, curr_forum: m1.forum.slug
    end

    assert_response :success
    assert_not_nil assigns(:threads)

    assigns(:threads).each do |t|
      assert t.messages[0].attribs['classes'].include?('visited')
    end
  end

  test "plugin api: mark_read: not when anonym" do
    @controller.do_init

    m = FactoryGirl.create(:cf_message)

    assert_no_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    } do
      @controller.plugin_apis[:mark_read].call(m, nil)
    end
  end

  test "plugin api: mark_read: mark for user" do
    @controller.do_init

    m = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)

    assert_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    }, 1 do
      @controller.plugin_apis[:mark_read].call(m, user)
    end
  end

  test "plugin api: mark_read: mark both for user" do
    @controller.do_init

    m = FactoryGirl.create(:cf_message)
    m1 = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)

    assert_difference lambda {
      row = CfMessage.connection.execute("SELECT COUNT(*) AS cnt FROM read_messages")
      row[0]['cnt'].to_i
    }, 2 do
      @controller.plugin_apis[:mark_read].call([m, m1], user)
    end
  end

  test "is_read: nil when anonym" do
    @controller.do_init

    m = FactoryGirl.create(:cf_message)
    assert_nil @controller.plugin_apis[:is_read].call(m, nil)
  end

  test "is_read: empty when unread" do
    @controller.do_init

    user = FactoryGirl.create(:cf_user)

    m = FactoryGirl.create(:cf_message)
    assert_equal [], @controller.plugin_apis[:is_read].call(m, user)
  end

  test "is_read: message_id when read" do
    @controller.do_init

    user = FactoryGirl.create(:cf_user)
    m = FactoryGirl.create(:cf_message)

    CfMessage.connection.execute "INSERT INTO read_messages (user_id, message_id) VALUES (" + user.user_id.to_s + ", " + m.message_id.to_s + ")"

    assert_equal [m.message_id], @controller.plugin_apis[:is_read].call(m, user)
  end

end

# eof