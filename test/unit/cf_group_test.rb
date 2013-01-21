# -*- coding: utf-8 -*-

require 'test_helper'

class CfGroupTest < ActiveSupport::TestCase

  test "test validations" do
    g = CfGroup.new
    assert !g.save

    g.name = "The Rebellion"
    assert g.save
  end

  test "test forums_groups_permissions relation" do
    g = FactoryGirl.create(:cf_group)

    f = FactoryGirl.create(:cf_forum)
    f1 = FactoryGirl.create(:cf_forum)

    g1 = CfGroup.find(g.group_id)
    assert_empty g1.forums_groups_permissions

    g.forums_groups_permissions << CfForumGroupPermission.new(group_id: g.group_id, forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ)
    assert g.save

    g1 = CfGroup.find(g.group_id)
    assert_not_empty g.forums_groups_permissions
    assert_equal 1, g.forums_groups_permissions.length

    g.forums_groups_permissions << CfForumGroupPermission.new(group_id: g.group_id, forum_id: f1.forum_id, permission: CfForumGroupPermission::ACCESS_READ)
    assert g.save

    g1 = CfGroup.find(g.group_id)
    assert_not_empty g.forums_groups_permissions
    assert_equal 2, g.forums_groups_permissions.length
  end

  test "test users relation" do
    g = FactoryGirl.create(:cf_group)

    u = FactoryGirl.create(:cf_user)
    u1 = FactoryGirl.create(:cf_user)

    g1 = CfGroup.find(g.group_id)
    assert_empty g1.users

    g.users << u
    assert g.save

    g1 = CfGroup.find(g.group_id)
    assert_not_empty g.users
    assert_equal 1, g.users.length

    g.users << u1
    assert g.save

    g1 = CfGroup.find(g.group_id)
    assert_not_empty g.users
    assert_equal 2, g.users.length
  end

end


# eof
