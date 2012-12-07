# -*- coding: utf-8 -*-

require 'test_helper'

class CfForumsControllerTest < ActionController::TestCase
  test "should work with empty list" do
    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [], assigns(:forums)
  end

  test "should show index of forums w/o private" do
    forum_public = FactoryGirl.create(:cf_forum)
    forum_priv   = FactoryGirl.create(:cf_forum, :public => false)

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [forum_public], assigns(:forums)
  end

  test "should show index of forums w/o private also if user signed in" do
    forum_public = FactoryGirl.create(:cf_forum)
    forum_priv   = FactoryGirl.create(:cf_forum, :public => false)
    user         = FactoryGirl.create(:cf_user, admin: false)

    assert !user.admin
    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [forum_public], assigns(:forums)
  end

  test "should show index of forums w private because of admin" do
    forum_public = FactoryGirl.create(:cf_forum)
    forum_priv   = FactoryGirl.create(:cf_forum, :public => false)
    user         = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test "should show index of forums w private because of permissions" do
    forum_public = FactoryGirl.create(:cf_forum)
    forum_priv   = FactoryGirl.create(:cf_forum, :public => false)
    user         = FactoryGirl.create(:cf_user, admin: false)

    cfp = CfForumPermission.create!(forum_id: forum_priv.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)

    cfp.permission = CfForumPermission::ACCESS_WRITE
    cfp.save

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)

    cfp.permission = CfForumPermission::ACCESS_MODERATOR
    cfp.save

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test 'should ignore t= and m=' do
    get :index, {t: 1, m: 1}
    assert_response :success
    assert_not_nil assigns(:forums)

    get :index, {t: 1}

    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 2
    message.save

    get :index, {t: 2, m: 3}
    assert_response :success
    assert_not_nil assigns(:forums)

    get :index, {t: 2}
    assert_response :success
    assert_not_nil assigns(:forums)
  end

  test 'should redirect to new uri' do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 1
    message.save

    get :index, {t: 1}
    assert_redirected_to cf_thread_path(message.thread)

    get :index, {t: 1, m: 1}
    assert_redirected_to cf_message_path(message.thread, message)
  end

  test 'old archive uri' do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 1
    message.save

    get :redirect_archive, {year: message.created_at.strftime("%Y"), mon: message.created_at.strftime("%m"), tid: 't' + message.thread.tid.to_s}
    assert_redirected_to cf_thread_path(message.thread)

    got_it = false
    begin
      get :redirect_archive, {year: message.created_at.strftime("%Y"), mon: message.created_at.strftime("%m"), tid: 't333' + message.thread.tid.to_s}
    rescue CForum::NotFoundException
      got_it = true
    end

    assert got_it
  end

end

# eof