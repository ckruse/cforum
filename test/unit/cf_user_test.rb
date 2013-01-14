# -*- coding: utf-8 -*-

require 'test_helper'

class CfUserTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  test "user should not save without username and email and password" do
    u = CfUser.new
    assert !u.save

    u.username = 'test-user'
    assert !u.save

    u.username = 'test-user'
    u.email    = 'user@example.org'
    assert !u.save

    u.username = nil
    u.email    = 'user@example.org'
    u.password = 'some weird password'
    assert !u.save

    u.username = 'test-user'
    u.password = 'user@example.org'
    u.email    = nil
    assert !u.save
  end

  test "user should save and destroy" do
    u = FactoryGirl.build(:cf_user)

    assert u.save
    assert_equal CfUser.all.length, 1

    assert u.destroy
    assert_equal CfUser.all.length, 0
  end

  test "username should be unique" do
    u = FactoryGirl.build(:cf_user)
    u1 = FactoryGirl.build(:cf_user)

    u1.username = u.username
    assert u.save
    assert !u1.save
  end

  test "email should be unique" do
    u = FactoryGirl.build(:cf_user)
    u1 = FactoryGirl.build(:cf_user)

    u1.email = u.email
    assert u.save
    assert !u1.save
  end

  test "check if permissions work" do
    u = FactoryGirl.create(:cf_user, :admin => false)
    f = FactoryGirl.create(:cf_forum)
    g = FactoryGirl.create(:cf_group)

    g.users << u

    assert !u.read?(f)

    p = CfForumGroupPermission.create!(forum_id: f.forum_id, permission: CfForumGroupPermission::ACCESS_READ, group_id: g.group_id)

    assert !u.moderate?(f)
    assert !u.write?(f)
    assert u.read?(f)

    p.update_attributes(permission: CfForumGroupPermission::ACCESS_WRITE)

    assert !u.moderate?(f)
    assert u.write?(f)
    assert u.read?(f)

    p.update_attributes(permission: CfForumGroupPermission::ACCESS_MODERATE)

    assert u.moderate?(f)
    assert u.write?(f)
    assert u.read?(f)
  end

  test "test to_param" do
    u = FactoryGirl.create(:cf_user)
    assert_equal u.user_id.to_s, u.to_param
  end

  test "test conf" do
    u = FactoryGirl.create(:cf_user)
    s = FactoryGirl.create(:cf_setting)

    s.options = {}
    s.options['blub'] = 'blah'
    s.save

    assert_blank u.conf('blub')

    s.user_id = u.user_id
    s.save
    u.reload

    assert_equal u.conf('blub'), 'blah'
  end

  test "should find first by auth condition" do
    u = FactoryGirl.create(:cf_user)
    u1 = CfUser.find_first_by_auth_conditions(login: u.username)

    assert_not_nil u1
    assert_equal u.user_id, u1.user_id

    u1 = CfUser.find_first_by_auth_conditions(email: u.email)
    assert_not_nil u1
    assert_equal u.user_id, u1.user_id
  end

  test "should not find first by auth condition" do
    u = FactoryGirl.create(:cf_user)

    u1 = CfUser.find_first_by_auth_conditions(login: u.username + "-lala")
    assert_nil u1

    u1 = CfUser.find_first_by_auth_conditions(email: u.email + "-lala")
    assert_nil u1
  end

end


# eof
