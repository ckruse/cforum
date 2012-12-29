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
  end

  test "should not destroy message because of non-existant message" do
  end

  test "should destroy message" do
  end

end

# eof
