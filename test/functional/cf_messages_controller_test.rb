# -*- coding: utf-8 -*-

require 'test_helper'

class CfMessagesControllerTest < ActionController::TestCase
  test "show: should fail because of wrong parameters" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'feb', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show message in public forum" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should not show deleted message because of anonymous" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}
    end
  end

  test "show: should not show deleted message because of permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}
    end
  end

  test "show: should not show deleted message because of admin and not view_all" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show deleted message because of admin and view_all" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert assigns(:message).deleted
  end

  test "show: should not show deleted message because of read permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}
    end
  end

  test "show: should not show deleted message because of write permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}
    end
  end

  test "show: should not show deleted message because of moderator permissions and not view_all" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    assert_raise(CForum::NotFoundException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show deleted message because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id, view_all: true}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert assigns(:message).deleted
  end

  test "show: should fail in private forum because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should fail in private forum because of permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show message in private forum because of admin" do
    forum   = FactoryGirl.create(:cf_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should show message in private forum because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "show: should show message in private forum because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user
    get :show, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end


  test "show: should show new in public forum" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "show: should not show new in private forum because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should not show new in private forum because of permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should not show new in private forum because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "show: should show new in private forum because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "show: should show new in private forum because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
  end

  test "create: should not create new message in public forum because of invalid" do
    forum = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_no_difference 'CfMessage.count' do
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
    end

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:parent)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).valid?
  end

  test "create: should create new message in public forum" do
    forum = FactoryGirl.create(:cf_write_forum)
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
    forum = FactoryGirl.create(:cf_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

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
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

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
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

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
    forum   = FactoryGirl.create(:cf_write_forum)
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

  test "destroy: should not destroy because of anonymous" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "destroy: should not destroy because of permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "destroy: should destroy because of admin" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert assigns(:message).deleted

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message), view_all: 'true')
  end

  test "destroy: should not destroy because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "destroy: should not destroy because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "destroy: should destroy because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user
    delete :destroy, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert assigns(:message).deleted

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message), view_all: 'true')
  end


  test "restore: should not restore because of anonymous" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)

    assert_raise(CForum::ForbiddenException) do
      post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "restore: should not restore because of permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "restore: should restore because of admin" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user

    post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).deleted

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message), view_all: 'true')
  end

  test "restore: should not restore because of read permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "restore: should not restore because of write permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test "restore: should restore because of moderator permissions" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi')
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user
    cfg = CfForumGroupPermission.create!(forum_id: forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    post :restore, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}

    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).deleted

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message), view_all: 'true')
  end

  test 'should not show new form on archived thread' do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    CfSetting.create!(forum_id: forum.forum_id, options: {'use_archive' => 'yes'})

    assert_raise CForum::ForbiddenException do
      get :new, {curr_forum: forum.slug, year: '2012', mon: 'dec', day: '6', tid: 'obi-wan-kenobi', mid: message.message_id}
    end
  end

  test 'should not post do archived thread' do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum, slug: '/2012/dec/6/obi-wan-kenobi', archived: true)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    CfSetting.create!(forum_id: forum.forum_id, options: {'use_archive' => 'yes'})

    assert_raise CForum::ForbiddenException do
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

end

# eof
