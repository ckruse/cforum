# -*- coding: utf-8 -*-

require 'test_helper'

class MailsControllerTest < ActionController::TestCase
  test "should not show index because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "should show empty index" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    get :index
    assert_response :success
    assert_not_nil assigns(:mails)
    assert_empty assigns(:mails)
  end

  test "should show index" do
    usr = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: usr)
    sign_in usr

    get :index
    assert_response :success
    assert_not_nil assigns(:mails)
    assert_not_empty assigns(:mails)
  end

  test "should show all of user" do
    usr = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: usr)
    sign_in usr

    get :index, {user: msg.sender.username}
    assert_response :success
    assert_not_nil assigns(:mails)
    assert_not_empty assigns(:mails)
  end

  test "should not show message because of anonymous" do
    usr = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: usr)

    assert_raise CForum::ForbiddenException do
      get :show, {user: msg.sender.username, id: msg.priv_message_id}
    end
  end

  test "should show message" do
    usr = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: usr)
    sign_in usr

    get :show, {user: msg.sender.username, id: msg.priv_message_id}
    assert_response :success
    assert !assigns(:mail).blank?
  end

  test "should not show message of other user" do
    usr = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      get :show, {user: msg.sender.username, id: msg.priv_message_id}
    end
  end

  test "should not show new because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :new
    end
  end

  test "should show new" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    get :new
    assert_response :success
    assert_not_nil assigns(:mail)
  end

  test "should not create because of anonymous" do
    usr = FactoryGirl.create(:cf_user)

    assert_raise CForum::ForbiddenException do
      post :create, cf_priv_message: {recipient_id: usr.user_id, subject: 'You are my only hope!', body: 'Help me, Obi-Wan Kenobi! You are my only hope!'}
    end
  end

  test "should not create because of invalid" do
    usr = FactoryGirl.create(:cf_user)
    recp = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_no_difference 'CfPrivMessage.count' do
      post :create, cf_priv_message: {recipient_id: recp.user_id, subject: '', body: 'Help me, Obi-Wan Kenobi! You are my only hope!'}
    end

    assert_response :success
    assert_not_nil assigns(:mail)
  end

  test "should not create because of non-existant recipient" do
    usr = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_no_difference 'CfPrivMessage.count' do
      assert_raise ActiveRecord::RecordNotFound do
        post :create, cf_priv_message: {recipient_id: 13232423, subject: 'You are my only hope!', body: 'Help me, Obi-Wan Kenobi! You are my only hope!'}
      end
    end
  end

  test "should create new mail" do
    usr = FactoryGirl.create(:cf_user)
    recp = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_difference 'CfPrivMessage.count', 2 do
      post :create, cf_priv_message: {recipient_id: recp.user_id, subject: 'You are my only hope!', body: 'Help me, Obi-Wan Kenobi! You are my only hope!'}
    end

    assert_redirected_to mail_url(assigns(:mail).recipient.username, assigns(:mail))
    assert_not_nil assigns(:mail)
  end

  test "should not destroy message because of anonymous" do
    msg = FactoryGirl.create(:cf_priv_message)

    assert_raise CForum::ForbiddenException do
      delete :destroy, user: msg.recipient.username, id: msg.priv_message_id
    end
  end

  test "should not destroy message because of non-existant message" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, user: 'lulu', id: 2131312312312
    end
  end

  test "should destroy message" do
    msg = FactoryGirl.create(:cf_priv_message)
    sign_in msg.owner

    delete :destroy, user: msg.recipient.username, id: msg.priv_message_id
    assert_redirected_to mails_url
  end

  test "should not create because of empty recipients" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    assert_no_difference 'CfPrivMessage.count' do
      post :create, cf_priv_message: {subject: 'You are my only hope!', body: 'Help me, Obi-Wan Kenobi! You are my only hope!'}
    end
  end

  test "should batch destroy mails" do
    u = FactoryGirl.create(:cf_user)
    msg1 = FactoryGirl.create(:cf_priv_message, owner: u)
    msg2 = FactoryGirl.create(:cf_priv_message, owner: u)
    msg3 = FactoryGirl.create(:cf_priv_message, owner: u)

    sign_in u

    assert_difference 'CfPrivMessage.count', -3 do
      post :batch_destroy, ids: [msg1.priv_message_id, msg2.priv_message_id, msg3.priv_message_id]
    end

    assert_redirected_to mails_url
  end

  test "should not crash while batch destroying mails" do
    u = FactoryGirl.create(:cf_user)
    sign_in u

    post :batch_destroy
    assert_redirected_to mails_url
  end

  test "should not batch destroy mails" do
    u = FactoryGirl.create(:cf_user)
    msg1 = FactoryGirl.create(:cf_priv_message)
    msg2 = FactoryGirl.create(:cf_priv_message)
    msg3 = FactoryGirl.create(:cf_priv_message)

    sign_in u

    assert_no_difference 'CfPrivMessage.count' do
      post :batch_destroy, ids: [msg1.priv_message_id, msg2.priv_message_id, msg3.priv_message_id]
    end

    assert_redirected_to mails_url
  end

  test "test answering" do
    u = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: u, recipient: u)

    sign_in u

    get :new, priv_message_id: msg.priv_message_id
    assert_response :success
    assert_not_nil assigns(:mail)
    assert_equal msg.sender_id, assigns(:mail).recipient_id
    assert_equal 'Re: ' + msg.subject, assigns(:mail).subject
  end

  test "should delete notification" do
    u = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: u, recipient: u)

    CfNotification.create!(
      recipient_id: u.user_id,
      is_read: false,
      path: 'wefwefewf',
      subject: "You're my only hope!",
      icon: nil,
      oid: msg.priv_message_id,
      otype: 'mails:create'
    )

    sign_in u

    assert_difference 'CfNotification.count', -1 do
      get :show, user: msg.sender.username, id: msg.priv_message_id
    end

    assert_response :success
    assert_not_nil assigns(:new_notifications)
    assert_empty assigns(:new_notifications)
  end

  test "should not delete notification but mark it read" do
    u = FactoryGirl.create(:cf_user)
    msg = FactoryGirl.create(:cf_priv_message, owner: u, recipient: u)

    CfSetting.create!(
      user_id: u.user_id,
      options: {'delete_read_notifications_on_new_mail' => 'no'}
    )

    CfNotification.create!(
      recipient_id: u.user_id,
      is_read: false,
      path: 'wefwefewf',
      subject: "You're my only hope!",
      icon: nil,
      oid: msg.priv_message_id,
      otype: 'mails:create'
    )

    sign_in u

    assert_no_difference 'CfNotification.count' do
      get :show, user: msg.sender.username, id: msg.priv_message_id
    end

    assert_response :success
    assert_not_nil assigns(:new_notifications)
    assert_empty assigns(:new_notifications)
  end

end

# eof
