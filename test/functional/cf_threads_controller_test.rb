# -*- coding: utf-8 -*-

require 'test_helper'

class CfThreadsControllerTest < ActionController::TestCase
  test "index: should work with empty list on public and empty forum" do
    forum = FactoryGirl.create(:cf_write_forum)
    user  = FactoryGirl.create(:cf_user)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should work with empty list on public forum and empty thread" do
    forum = FactoryGirl.create(:cf_write_forum)
    user  = FactoryGirl.create(:cf_user)
    thread = FactoryGirl.create(:cf_thread, forum: forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should work with empty list on public forum and deleted thread" do
    forum = FactoryGirl.create(:cf_write_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
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
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should show index in private forum because of write permission" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: should should index in private forum because of moderator permission" do
    forum   = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

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

  test "index: should show list of all threads and tags" do
    msg = FactoryGirl.create(:cf_message)
    msg1 = FactoryGirl.create(:cf_message)

    tag1 = FactoryGirl.create(:cf_tag)
    tag2 = FactoryGirl.create(:cf_tag)

    CfMessageTag.create!(message_id: msg.message_id, tag_id: tag1.tag_id)
    CfMessageTag.create!(message_id: msg.message_id, tag_id: tag2.tag_id)
    CfMessageTag.create!(message_id: msg1.message_id, tag_id: tag1.tag_id)
    CfMessageTag.create!(message_id: msg1.message_id, tag_id: tag2.tag_id)

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
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: permissions with access write" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: permissions with access moderator and view_all" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :index, {curr_forum: forum.slug, view_all: true}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "index: permissions with access moderator" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: false)
    thread  = FactoryGirl.create(:cf_thread, forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread, deleted: true)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 0, assigns(:threads).length
  end

  test "index: should fail with forbidden" do
    forum = FactoryGirl.create(:cf_forum)
    thread = FactoryGirl.create(:cf_thread, forum: forum)

    assert_raise(CForum::ForbiddenException) do
      get :index, {curr_forum: forum.slug}
    end
  end

  test "index: should fail with forbidden even with user" do
    forum  = FactoryGirl.create(:cf_forum)
    thread = FactoryGirl.create(:cf_thread, forum: forum)
    user   = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :index, {curr_forum: forum.slug}
    end
  end


  test "new: should show form" do
    forum   = FactoryGirl.create(:cf_write_forum)

    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should fail because of permissions on private forum" do
    forum   = FactoryGirl.create(:cf_forum)

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug}
    end
  end

  test "new: should show form in private forum because of admin" do
    forum   = FactoryGirl.create(:cf_forum)
    user    = FactoryGirl.create(:cf_user, admin: true)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should fail because of private forum and only read access" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :new, {curr_forum: forum.slug}
    end
  end

  test "new: should show form in private forum because of write access" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "new: should show form in private forum because of moderator access" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user
    get :new, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:thread).message
  end

  test "create: should not create a new thread in public forum because of invalid subject" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_no_difference 'CfThread.count' do
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: '', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    end

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).valid?
  end
  test "create: should not create a new thread in public forum because of invalid author" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_no_difference 'CfThread.count' do
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: '', content: 'Long live the imperator! Down with the rebellion!'}}}
    end

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).valid?
  end
  test "create: should not create a new thread in public forum because of invalid content" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_no_difference 'CfThread.count' do
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: ''}}}
    end

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert !assigns(:message).valid?
  end

  test "create: should generate a preview in public forum" do
    forum = FactoryGirl.create(:cf_write_forum)

    cnt = CfThread.count

    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create a new thread with different slug" do
    forum = FactoryGirl.create(:cf_write_forum)
    post_data = {
      curr_forum: forum.slug,
      cf_thread: {
        message: {
          subject: 'Long live the imperator!',
          author: 'Anaken Skywalker',
          content: 'Long live the imperator! Down with the rebellion!'
        }
      }
    }

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, post_data
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))

    t = assigns(:thread)

    post :create, post_data
    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    assert_not_equal t.slug, assigns(:thread).slug

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should create new thread in public forum" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert assigns(:message).tags.blank?

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should create new thread in public forum with tags" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {
          tags: %w{test1 test2 test3},
          curr_forum: forum.slug,
          cf_thread: {
            message: {
              subject: 'Long live the imperator!',
              author: 'Anaken Skywalker',
              content: 'Long live the imperator! Down with the rebellion!'
            }
          }
        }
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    m = assigns(:message)
    assert_equal 3, m.tags.length
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test1'}
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test2'}
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test3'}

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should create new thread in public forum with tag list" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_difference('CfThread.count') do
      assert_difference('CfMessage.count') do
        post :create, {
          tag_list: "test1, test2, test3",
          curr_forum: forum.slug,
          cf_thread: {
            message: {
              subject: 'Long live the imperator!',
              author: 'Anaken Skywalker',
              content: 'Long live the imperator! Down with the rebellion!'
            }
          }
        }
      end
    end

    assert_not_nil flash[:notice]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)

    m = assigns(:message)
    assert_equal 3, m.tags.length
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test1'}
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test2'}
    assert_not_nil m.tags.find {|tag| tag.tag_name == 'test3'}

    assert_redirected_to cf_message_url(assigns(:thread), assigns(:message))
  end

  test "create: should not create new thread in public forum because of invalid tag" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_no_difference('CfThread.count') do
      assert_no_difference('CfMessage.count') do
        post :create, {
          tags: %w{t},
          curr_forum: forum.slug,
          cf_thread: {
            message: {
              subject: 'Long live the imperator!',
              author: 'Anaken Skywalker',
              content: 'Long live the imperator! Down with the rebellion!'
            }
          }
        }
      end
    end

    assert_not_nil flash[:error]
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
    assert_not_nil assigns(:message).tags

    assert_response :success
  end

  test "create: should not generate a preview in non-public forum" do
    forum = FactoryGirl.create(:cf_forum)

    assert_raise(CForum::ForbiddenException) do
      post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    end
  end

  test "create: should not create a thread in non-public forum" do
    forum = FactoryGirl.create(:cf_forum)

    assert_raise(CForum::ForbiddenException) do
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    end
  end

  test "create: should generate a preview in non-public forum because of admin" do
    forum = FactoryGirl.create(:cf_forum)
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
    forum = FactoryGirl.create(:cf_write_forum)
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
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    end
  end

  test "create: should not create new thread in non-public forum because of read permission" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      post :create, {curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}
    end
  end

  test "create: should generate a preview in non-public forum because of write permission" do
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    cnt = CfThread.count

    sign_in user
    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in non-public forum because of write permission" do
    forum = FactoryGirl.create(:cf_write_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

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
    forum = FactoryGirl.create(:cf_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    cnt = CfThread.count

    sign_in user
    post :create, {preview: true, curr_forum: forum.slug, cf_thread: { message: {subject: 'Long live the imperator!', author: 'Anaken Skywalker', content: 'Long live the imperator! Down with the rebellion!'}}}

    assert_equal cnt, CfThread.count

    assert_response :success
    assert_not_nil assigns(:message)
    assert_not_nil assigns(:thread)
  end

  test "create: should create new thread in non-public forum because of moderator permission" do
    forum = FactoryGirl.create(:cf_write_forum)
    user  = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

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
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)

    assert_raise(CForum::ForbiddenException) do
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    end
  end

  test "moving: should not show form because of permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    end
  end

  test "moving: should not show form because of read permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    end
  end

  test "moving: should not show form because of write permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}
    end
  end

  test "moving: should show form because of admin" do
    forum   = FactoryGirl.create(:cf_write_forum)
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
    forum   = FactoryGirl.create(:cf_write_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

    sign_in user

    get :moving, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug}

    assert_response :success
    assert_not_nil assigns(:forums)
    assert_not_nil assigns(:thread)
  end


  test "move: should not move because of anonymous" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)


    assert_raise(CForum::ForbiddenException) do
      post :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should not move because of authorization" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should not move because of read permission only in forum" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    cpp = CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should not move because of read permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)
    CfForumGroupPermission.create!(:forum_id => forum1.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should not move because of write permission only in forum" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should not move because of write permissions" do
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: false)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)
    CfForumGroupPermission.create!(:forum_id => forum1.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_WRITE)

    sign_in user

    assert_raise(CForum::ForbiddenException) do
      get :move, {year: '2012', mon: 'dec', day: '6', tid: 'star-wars', curr_forum: thread.forum.slug, move_to: forum1.forum_id}
    end
  end

  test "move: should move because of admin" do
    forum   = FactoryGirl.create(:cf_write_forum)
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
    forum   = FactoryGirl.create(:cf_write_forum)
    forum1  = FactoryGirl.create(:cf_forum)
    thread  = FactoryGirl.create(:cf_thread, slug: '/2012/dec/6/star-wars', forum: forum)
    message = FactoryGirl.create(:cf_message, forum: forum, thread: thread)
    user    = FactoryGirl.create(:cf_user, admin: true)
    group   = FactoryGirl.create(:cf_group)

    group.users << user

    CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)
    CfForumGroupPermission.create!(:forum_id => forum1.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_MODERATE)

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

  test "should show /all to anonymous" do
    user = FactoryGirl.create(:cf_user, admin: false)
    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "should show /all to user" do
    user = FactoryGirl.create(:cf_user, admin: false)
    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "should show /all wo threads of private forum to anonymous" do
    forum = FactoryGirl.create(:cf_forum)

    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    t1 = FactoryGirl.create(:cf_thread, forum: forum)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: t1)

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "should show /all wo threads of private forum" do
    user = FactoryGirl.create(:cf_user, admin: false)
    forum = FactoryGirl.create(:cf_forum)

    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    t1 = FactoryGirl.create(:cf_thread, forum: forum)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: t1)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 1, assigns(:threads).length
  end

  test "should show /all with threads of private forum because of rights" do
    user = FactoryGirl.create(:cf_user, admin: false)
    group = FactoryGirl.create(:cf_group)
    forum = FactoryGirl.create(:cf_forum)

    group.users << user

    CfForumGroupPermission.create!(:forum_id => forum.forum_id, group_id: group.group_id, permission: CfForumGroupPermission::ACCESS_READ)

    t = FactoryGirl.create(:cf_thread)
    message = FactoryGirl.create(:cf_message, forum: t.forum, thread: t)

    t1 = FactoryGirl.create(:cf_thread, forum: forum)
    message1 = FactoryGirl.create(:cf_message, forum: forum, thread: t1)

    sign_in user

    get :index
    assert_response :success
    assert_not_nil assigns(:threads)
    assert_equal 2, assigns(:threads).length
  end

end

# eof
