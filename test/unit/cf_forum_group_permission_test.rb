# -*- coding: utf-8 -*-

require 'test_helper'

class CfForumGroupPermissionTest < ActiveSupport::TestCase

  test "test validations" do
    g = FactoryGirl.create(:cf_group)
    f = FactoryGirl.create(:cf_forum)

    p = CfForumGroupPermission.new
    assert !p.save

    p.group_id = g.group_id
    assert !p.save

    p.forum_id = f.forum_id
    assert !p.save

    p.permission = CfForumGroupPermission::ACCESS_READ
    assert p.save

    p.permission = 'ewfwfe'
    assert !p.save
  end

  test "test forum relation" do
    f = FactoryGirl.create(:cf_forum)
    fgp = FactoryGirl.create(:cf_forum_group_permission)

    fgp1 = CfForumGroupPermission.find(fgp.forum_group_permission_id)
    assert_not_nil fgp1.forum

    fgp.forum = f
    assert fgp.save

    fgp1 = CfForumGroupPermission.find(fgp.forum_group_permission_id)
    assert_not_nil fgp1.forum
    assert_equal f.forum_id, fgp1.forum.forum_id
  end

  test "test group relation" do
    g = FactoryGirl.create(:cf_group)
    fgp = FactoryGirl.create(:cf_forum_group_permission)

    fgp1 = CfForumGroupPermission.find(fgp.forum_group_permission_id)
    assert_not_nil fgp1.group

    fgp.group = g
    assert fgp.save

    fgp1 = CfForumGroupPermission.find(fgp.forum_group_permission_id)
    assert_not_nil fgp1.group
    assert_equal g.group_id, fgp1.group.group_id
  end
end


# eof
