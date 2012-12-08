# -*- coding: utf-8 -*-

require 'test_helper'

class CfThreadsControllerTest < ActionController::TestCase
  test "index: should work with empty list on public and empty forum" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should work with empty list on public forum and empty thread" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user)
    thread = FactoryGirl.create(:cf_thread, forum: forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should work with empty list on public forum and deleted thread" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user)
    thread = FactoryGirl.create(:cf_thread, forum: forum)
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
  end

  test "index: should show index in private forum because of read permission" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    cpp = CfForumPermission.create!(:forum_id => forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should show index in private forum because of write permission" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    cpp = CfForumPermission.create!(:forum_id => forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should should index in private forum because of moderator permission" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    cpp = CfForumPermission.create!(:forum_id => forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user

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
  end

  test "index: should show list of all threads w/o deleted" do
    msg = FactoryGirl.create(:cf_message)
    msg1 = FactoryGirl.create(:cf_message, deleted: true)

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should show list of all threads w/o deleted even w view_all" do
    msg = FactoryGirl.create(:cf_message)
    msg1 = FactoryGirl.create(:cf_message, deleted: true)

    get :index, {view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: permissions with access read" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: permissions with access write" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: permissions with access moderator and view_all" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: permissions with access moderator" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should fail with forbidden" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    thread = FactoryGirl.create(:cf_thread, forum: forum)

    catched = false
    begin
      get :index, {curr_forum: forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "index: should fail with forbidden even with user" do
    forum  = FactoryGirl.create(:cf_forum, :public => false)
    thread = FactoryGirl.create(:cf_thread, forum: forum)
    user   = FactoryGirl.create(:cf_user, admin: false)

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

  test "show: failing to access with anonymous access" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    catched = false
    begin
      get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub'}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "show: permissions with admin access to private forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user
    get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub'}
    assert_response :success
  end

  test "show: permissions with read access to private forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user
    cpp = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_READ)
    get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub', view_all: true}
    assert_response :success
  end

  test "show: permissions with write access to private forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user
    cpp = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_WRITE)
    get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub', view_all: true}
    assert_response :success
  end

  test "show: permissions with moderator access to private forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: DateTime.now.strftime("/%Y/%b/%d").downcase + '/blub')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user
    cpp = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_MODERATOR)
    get :show, {curr_forum: forum.slug, year: thread.created_at.strftime("%Y"), mon: thread.created_at.strftime("%b").downcase, day: thread.created_at.strftime("%d"), tid: 'blub', view_all: true}
    assert_response :success
  end

  test "new: should show form" do
    forum   = FactoryGirl.create(:cf_forum)

    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should fail because of permissions on private forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)

    catched = false
    begin
      get :new, {curr_forum: forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "new: should show form in private forum because of admin" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should fail because of private forum and only read access" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      get :new, {curr_forum: forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "new: should show form in private forum because of write access" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should show form in private forum because of moderator access" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create!(user_id: user.user_id, forum_id: forum.forum_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "create: should generate a preview in public forum" do
    forum = FactoryGirl.create(:cf_forum, :public => true)

    cnt = CfThread.count

    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in public forum" do
    forum = FactoryGirl.create(:cf_forum, :public => true)

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should not generate a preview in non-public forum" do
    forum = FactoryGirl.create(:cf_forum, :public => false)

    catched = false
    begin
      post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "create: should not create a thread in non-public forum" do
    forum = FactoryGirl.create(:cf_forum, :public => false)

    catched = false
    begin
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "create: should generate a preview in non-public forum because of admin" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user = FactoryGirl.create(:cf_user, admin: true)

    cnt = CfThread.count

    sign_in user
    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in non-public forum because of admin" do
    forum = FactoryGirl.create(:cf_forum, :public => true)
    user  = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should not generate a preview in non-public forum because of read permission" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "create: should not create new thread in non-public forum because of read permission" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "create: should generate a preview in non-public forum because of write permission" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    cnt = CfThread.count

    sign_in user
    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in non-public forum because of write permission" do
    forum = FactoryGirl.create(:cf_forum, :public => true)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should generate a preview in non-public forum because of moderator permission" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    cnt = CfThread.count

    sign_in user
    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in non-public forum because of moderator permission" do
    forum = FactoryGirl.create(:cf_forum, :public => true)
    user  = FactoryGirl.create(:cf_user, admin: false)
    cpp   = CfForumPermission.create(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "moving: should not show form because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    catched = false
    begin
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "moving: should not show form because of permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    catched = false
    begin
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "moving: should not show form because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "moving: should not show form because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "moving: should show form because of admin" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}

    assert_response :success
    assert_not_nil assigns(:forums)
    assert_not_nil assigns(:thread)
  end

  test "moving: should show form because of moderator permission" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    cpp     = CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user

    get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}

    assert_response :success
    assert_not_nil assigns(:forums)
    assert_not_nil assigns(:thread)
  end


  test "move: should not move because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)


    catched = false
    begin
      post :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should not move because of authorization" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    catched = false
    begin
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should not move because of read permission only in forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should not move because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)
    CfForumPermission.create!(forum_id: forum1.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    catched = false
    begin
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should not move because of write permission only in forum" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    catched = false
    begin
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should not move because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)
    CfForumPermission.create!(forum_id: forum1.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    catched = false
    begin
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    rescue CForum::ForbiddenException
      catched = true
    end
    assert catched
  end

  test "move: should move because of admin" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    cnt_forum  = forum.threads.count
    cnt_forum1 = forum1.threads.count

    sign_in user

    assert_difference lambda { forum.threads.count }, -1 do
      assert_difference lambda { forum1.threads.count }, +1 do
        get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
      end
    end

    assert_not_nil assigns(:thread)
    assert_not_nil flash[:notice]
    assert_redirected_to cf_message_url(assigns(:thread), assigns(:thread).message)
  end

  test "move: should move because of moderator" do
    forum   = FactoryGirl.create(:cf_forum, :public => true)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)
    CfForumPermission.create!(forum_id: forum1.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    cnt_forum  = forum.threads.count
    cnt_forum1 = forum1.threads.count

    sign_in user

    assert_difference lambda { forum.threads.count }, -1 do
      assert_difference lambda { forum1.threads.count }, +1 do
        get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
      end
    end

    assert_not_nil assigns(:thread)
    assert_not_nil flash[:notice]
    assert_redirected_to cf_message_url(assigns(:thread), assigns(:thread).message)
  end

end

# eof