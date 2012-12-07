# -*- coding: utf-8 -*-

require 'test_helper'

class CfForumPermissionTest < ActiveSupport::TestCase
  test "validations" do
    u = FactoryGirl.create(:cf_user)
    f = FactoryGirl.create(:cf_forum)

    p = CfForumPermission.new
    assert !p.save

    p.forum_id = f.forum_id
    assert !p.save

    p.user_id = u.user_id
    assert p.save
    assert_equal p.permission, 'read'

    p.permission = 'lulu'
    assert !p.save

    p.permission = CfForumPermission::ACCESS_READ
    assert p.save

    p.permission = CfForumPermission::ACCESS_WRITE
    assert p.save

    p.permission = CfForumPermission::ACCESS_MODERATOR
    assert p.save
  end

  test "relation forum" do
    u = FactoryGirl.create(:cf_user)
    f = FactoryGirl.create(:cf_forum)

    p = CfForumPermission.new
    assert_nil p.forum

    p.forum_id = f.forum_id
    p.user_id  = u.user_id
    p.save
    assert_not_nil p.forum_id
    assert_not_nil p.forum
  end

  test "relation user" do
    u = FactoryGirl.create(:cf_user)
    f = FactoryGirl.create(:cf_forum)

    p = CfForumPermission.new
    assert_nil p.user

    p.forum_id = f.forum_id
    p.user_id  = u.user_id
    p.save
    assert_not_nil p.user_id
    assert_not_nil p.user
  end

end


# eof
