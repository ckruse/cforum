# -*- coding: utf-8 -*-

require 'test_helper'

class CfForumTest < ActiveSupport::TestCase
  test "should not save forum" do
    f = CfForum.new()
    assert !f.save

    f.name = 'The Death Star'
    assert !f.save

    f.short_name = 'Death Star'
    assert !f.save

    f.slug = 'Death Star'
    assert !f.save

    f.slug = 'death-star'
    f.short_name = 'Death Star' * 50
    assert !f.save
  end

  test "should save forum" do
    f = CfForum.new(name: 'Planet Aldebaran', short_name: 'Aldebaran', :slug => 'aldebaran')
    assert f.save
    assert_equal 1, CfForum.count()
  end

  test "should not save forum because of slug uniqueness" do
    f = FactoryGirl.build(:cf_forum)
    f.slug = 'abc'
    f.save

    f1 = FactoryGirl.build(:cf_forum)
    f1.slug = 'abc'
    assert !f1.save
  end

  test "threads relation" do
    f = FactoryGirl.create(:cf_forum)
    t = FactoryGirl.create(:cf_thread, forum: f)

    assert_equal 1, f.threads.count()

    assert f.threads.clear
    assert_equal 0, f.threads.count()
  end

  test "permissions with not admin and private forum" do
    f = FactoryGirl.create(:cf_forum, :public => false)
    u = FactoryGirl.create(:cf_user, admin: false)

    assert !f.moderator?(u)
    assert !f.write?(u)
    assert !f.read?(u)

    perm = CfForumPermission.create!(user_id: u.user_id, forum_id: f.forum_id, permission: CfForumPermission::ACCESS_READ)
    f.forum_permissions.reload

    assert_equal 1, f.forum_permissions.count()

    assert !f.moderator?(u)
    assert !f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_WRITE)
    f.forum_permissions.reload

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_MODERATOR)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    assert f.forum_permissions.clear
    assert_equal 0, f.forum_permissions.count()
  end

  test "permissions with admin and private forum" do
    f = FactoryGirl.create(:cf_forum, :public => false)
    u = FactoryGirl.create(:cf_user, admin: true)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumPermission.create!(user_id: u.user_id, forum_id: f.forum_id, permission: CfForumPermission::ACCESS_READ)
    f.forum_permissions.reload

    assert_equal 1, f.forum_permissions.count()

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_WRITE)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_MODERATOR)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "permissions with not admin and public forum" do
    f = FactoryGirl.create(:cf_forum, :public => true)
    u = FactoryGirl.create(:cf_user, admin: false)

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumPermission.create!(user_id: u.user_id, forum_id: f.forum_id, permission: CfForumPermission::ACCESS_READ)
    f.forum_permissions.reload

    assert_equal 1, f.forum_permissions.count()

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_WRITE)
    f.forum_permissions.reload

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_MODERATOR)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "permissions with admin and public forum" do
    f = FactoryGirl.create(:cf_forum, :public => true)
    u = FactoryGirl.create(:cf_user, admin: true)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumPermission.create!(user_id: u.user_id, forum_id: f.forum_id, permission: CfForumPermission::ACCESS_READ)
    f.forum_permissions.reload

    assert_equal 1, f.forum_permissions.count()

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_WRITE)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumPermission::ACCESS_MODERATOR)
    f.forum_permissions.reload

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "users relation" do
    f = FactoryGirl.create(:cf_forum)
    u = FactoryGirl.create(:cf_user)

    f.users << u
    f = CfForum.find f.forum_id

    assert_equal 1, f.users.length

    assert f.users.clear
    assert_equal 0, f.users.count()
    assert_not_nil CfUser.find_by_user_id u.user_id
  end

  test "tags relation" do
    f = FactoryGirl.create(:cf_forum)

    f.tags << CfTag.new(tag_name: 'star wars')
    f = CfForum.find f.forum_id

    assert_equal 1, f.tags.length

    assert f.tags.clear
    assert_equal 0, f.tags.count()
  end

  test "to_param" do
    f = FactoryGirl.create(:cf_forum)
    assert_equal f.slug, f.to_param
  end

end


# eof
