# -*- coding: utf-8 -*-

require 'test_helper'

class CfGroupUserTest < ActiveSupport::TestCase

  test "test validations" do
    gu = CfGroupUser.new

    assert !gu.save

    u = FactoryGirl.create(:cf_user)
    gu.user_id = u.user_id
    assert !gu.save

    g = FactoryGirl.create(:cf_group)
    gu.group_id = g.group_id
    gu.user_id = nil
    assert !gu.save

    gu.user_id = u.user_id
    assert gu.save
  end


  test "user relation" do
    u = FactoryGirl.create(:cf_user)
    g = FactoryGirl.create(:cf_group)

    gu = CfGroupUser.create!(user_id: u.user_id, group_id: g.group_id)

    gu1 = CfGroupUser.find gu.group_user_id
    assert_not_nil gu1
    assert_not_nil gu1.user
    assert_equal gu1.user.user_id, u.user_id
  end

  test "group relation" do
    u = FactoryGirl.create(:cf_user)
    g = FactoryGirl.create(:cf_group)

    gu = CfGroupUser.create!(user_id: u.user_id, group_id: g.group_id)

    gu1 = CfGroupUser.find gu.group_user_id
    assert_not_nil gu1
    assert_not_nil gu1.group
    assert_equal gu1.group.group_id, g.group_id
  end

end


# eof
