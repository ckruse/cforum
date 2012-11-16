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
    f = FactoryGirl.create(:cf_forum, :public => false)

    assert !u.read?(f)

    p = CfForumPermission.create!(forum_id: f.forum_id, user_id: u.user_id, permission: 'read')
    u.rights.reload

    assert_equal u.rights.length, 1
    assert_equal u.rights[0].permission, 'read'
    assert_equal u.rights[0].forum_id, f.forum_id
    assert_equal u.rights[0].user_id, u.user_id

    assert !u.moderate?(f)
    assert !u.write?(f)
    assert u.read?(f)

    p.permission = 'write'
    p.save
    u.rights.reload

    assert !u.moderate?(f)
    assert u.write?(f)
    assert u.read?(f)

    p.permission = 'moderate'
    p.save
    u.rights.reload

    assert u.moderate?(f)
    assert u.write?(f)
    assert u.read?(f)
  end

  test "test to_param" do
    u = FactoryGirl.create(:cf_user)
    assert_equal u.username, u.to_param
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

end


# eof
