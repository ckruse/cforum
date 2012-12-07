# -*- coding: utf-8 -*-

require 'test_helper'

class CfThreadsControllerTest < ActionController::TestCase
  test "index: should work with empty list" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length

    thread = FactoryGirl.create(:cf_thread, forum: forum)
    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length

    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    message.deleted = true
    message.save

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should show index of threads" do
    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    get :index, {curr_forum: t.forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should show index in pviate forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length

    user.admin = false
    user.save
    cpp = CfForumPermission.create!(:forum_id => forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length

    cpp.permission = CfForumPermission::ACCESS_WRITE
    cpp.save

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length

    cpp.permission = CfForumPermission::ACCESS_MODERATOR
    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should show list of all threads" do
    msg = FactoryGirl.create(:cf_message)
    msg1 = FactoryGirl.create(:cf_message)

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 2, assigns(:threads).length

    msg1.deleted = true
    msg1.save

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length

    get :index, {view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    message.deleted = true
    message.save

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length

    cpp.update_attributes(permission: CfForumPermission::ACCESS_WRITE)
    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length

    cpp.update_attributes(permission: CfForumPermission::ACCESS_MODERATOR)
    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should fail with forbidden" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    thread = FactoryGirl.create(:cf_thread, forum: forum)
    user = FactoryGirl.create(:cf_user)

    catched = false
    begin
      get :index, {curr_forum: forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched

    sign_in user

    catched = false
    begin
      get :index, {curr_forum: forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "show: should show thread" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub'}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_nil assigns(:message)
    assert_equal message.thread.thread_id, assigns(:thread).thread_id
  end

  test "show: should not find thread" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    message.update_attributes(deleted: true)

    catched = false
    begin
      get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub'}
    rescue CForum::NotFoundException
      catched = true
    end

    assert catched
  end
end

# eof