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
    g = FactoryGirl.create(:cf_group)

    g.users << u

    assert !f.moderator?(u)
    assert !f.write?(u)
    assert !f.read?(u)

    perm = CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)

    assert_equal 1, f.forums_groups_permissions.count()

    assert !f.moderator?(u)
    assert !f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_WRITE)

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_MODERATE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    assert f.forums_groups_permissions.clear
    assert_equal 0, f.forums_groups_permissions.count()
  end

  test "permissions with admin and private forum" do
    f = FactoryGirl.create(:cf_forum, :public => false)
    u = FactoryGirl.create(:cf_user, admin: true)
    g = FactoryGirl.create(:cf_group)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)

    assert_equal 1, f.forums_groups_permissions.count()

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_WRITE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_MODERATE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "permissions with not admin and public forum" do
    f = FactoryGirl.create(:cf_forum, :public => true)
    u = FactoryGirl.create(:cf_user, admin: false)
    g = FactoryGirl.create(:cf_group)

    g.users << u

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)

    assert_equal 1, f.forums_groups_permissions.count()

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_WRITE)

    assert !f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_MODERATE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "permissions with admin and public forum" do
    f = FactoryGirl.create(:cf_forum, :public => true)
    u = FactoryGirl.create(:cf_user, admin: true)
    g = FactoryGirl.create(:cf_group)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm = CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)

    assert_equal 1, f.forums_groups_permissions.count()

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_WRITE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)

    perm.update_attributes(permission: CfForumGroupPermission::ACCESS_MODERATE)

    assert f.moderator?(u)
    assert f.write?(u)
    assert f.read?(u)
  end

  test "groups relation" do
    f = FactoryGirl.create(:cf_forum)
    g = FactoryGirl.create(:cf_group)

    f.forums_groups_permissions << CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)
    f = CfForum.find f.forum_id

    assert_equal 1, f.forums_groups_permissions.length

    assert f.forums_groups_permissions.clear
    assert_equal 0, f.forums_groups_permissions.count()
    assert_not_nil CfGroup.find_by_group_id g.group_id
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
