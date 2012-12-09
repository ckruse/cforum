# -*- coding: utf-8 -*-

require 'test_helper'

class CfMessagesControllerTest < ActionController::TestCase
  test "show: should fail because of wrong parameters" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'feb', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show message in public forum" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should fail in private forum because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should fail in private forum because of permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show message in private forum because of admin" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should show message in private forum because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should show message in private forum because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should show message in private forum because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end


  test "show: should show new in public forum" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "show: should not show new in private forum because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should not show new in private forum because of permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should not show new in private forum because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show new in private forum because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "show: should show new in private forum because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "create: should not create new message in public forum because of invalid" do
    forum = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    post :create, {
      curr_forum: forum.slug,
      year: '2012',
      mon: 'dec',
      day: '6',
      tid: 'obi-wan-kenobi',
      mid: message.message_id.to_s,
      cf_message: {
        subject: '',
        author: 'Anaken Skywalker',
        content: 'Long live the imperator! Down with the rebellion!'
      }
    }

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).valid?
  end

  test "create: should create new message in public forum" do
    forum = FactoryGirl.create(:cf_forum, :public => true)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_difference 'CfMessage.count' do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should not create new message in private forum because of anonymous" do
    forum = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end
  end

  test "create: should not create new message in private forum because of permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end
  end

  test "create: should create new message in private forum because of admin" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    assert_difference('CfMessage.count') do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should not create new message in private forum because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end
  end

  test "create: should create new message in private forum because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_WRITE)

    sign_in user

    assert_difference('CfMessage.count') do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should create new message in private forum because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum, :public => false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    CfForumPermission.create!(forum_id: forum.forum_id, user_id: user.user_id, permission: CfForumPermission::ACCESS_MODERATOR)

    sign_in user

    assert_difference('CfMessage.count') do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should show preview" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_no_difference('CfMessage.count') do
      post :create, {
        curr_forum: forum.slug,
        year: '2012',
        mon: 'dec',
        day: '6',
        tid: 'obi-wan-kenobi',
        mid: message.message_id.to_s,
        preview: true,
        cf_message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    end

    assert_response :success

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:preview)
  end

end

# eof