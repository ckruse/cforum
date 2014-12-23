# -*- coding: utf-8 -*-

require 'test_helper'

class CfForumsControllerTest < ActionController::TestCase
  test "should not load locked forums" do
    forum = FactoryGirl.create(:cf_write_forum)
    CfSetting.create(forum_id: forum.forum_id,
                     options: {'locked' => 'yes'})

    get :index, { curr_forum: forum.slug }
    assert_response 500

    get :index
    assert_response :success
  end

  test "should not load when globally locked" do
    forum = FactoryGirl.create(:cf_write_forum)
    CfSetting.create(options: {'locked' => 'yes'})

    get :index, { curr_forum: forum.slug }
    assert_response 500

    get :index
    assert_response 500
  end

  test "should load as admin when globally locked" do
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create(options: {'locked' => 'yes'})

    sign_in user

    get :index, { curr_forum: forum.slug }
    assert_response :success

    get :index
    assert_response :success
  end

  test "should work with empty list" do
    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [], assigns(:forums)
  end

  test "should show index of forums w/o private" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [forum_public], assigns(:forums)
  end

  test "should show index of forums w/o private also if user signed in" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)
    user         = FactoryGirl.create(:cf_user, admin: false)

    assert !user.admin
    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert_equal [forum_public], assigns(:forums)
  end

  test "should show index of forums w private because of admin" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)
    user         = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test "should show index of forums w private because of read permissions" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)
    user         = FactoryGirl.create(:cf_user, admin: false)
    group        = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum_priv.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test "should show index of forums w private because of write permissions" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)
    user         = FactoryGirl.create(:cf_user, admin: false)
    group        = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum_priv.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test "should show index of forums w private because of moderator permissions" do
    forum_public = FactoryGirl.create(:cf_write_forum)
    forum_priv   = FactoryGirl.create(:cf_forum)
    user         = FactoryGirl.create(:cf_user, admin: false)
    group        = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum_priv.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
    assert assigns(:forums).include?(forum_priv)
    assert assigns(:forums).include?(forum_public)
  end

  test 'should ignore t and m' do
    get :index, {t: 1, m: 1}
    assert_response :success
    assert_not_nil assigns(:forums)
  end

  test "should ignore t" do
    get :index, {t: 1}

    assert_response :success
    assert_not_nil assigns(:forums)
  end


  test "should ignore t and m with existing message but wrong tid and mid" do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 2
    message.save

    get :index, {t: 2, m: 3}
    assert_response :success
    assert_not_nil assigns(:forums)
  end

  test "should ignore t with existing thread but wrong tid" do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 2
    message.save

    get :index, {t: 2}
    assert_response :success
    assert_not_nil assigns(:forums)
  end

  test 'should redirect to new uri with t' do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 1
    message.save

    get :index, {t: 1}
    assert_redirected_to cf_thread_path(message.thread)
  end

  test 'should redirect to new uri with t and m' do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 1
    message.save

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
    assert_redirected_to cf_message_path(message.thread, message)
  end

  test 'old archive uri with non-existant uri' do
    message = FactoryGirl.create(:cf_message)
    message.thread.tid = 1
    message.thread.save
    message.mid = 1
    message.save

    assert_raise(CForum::NotFoundException) do
      get :redirect_archive, {year: message.created_at.strftime("%Y"), mon: message.created_at.strftime("%m"), tid: 't333' + message.thread.tid.to_s}
    end
  end

end

# eof
