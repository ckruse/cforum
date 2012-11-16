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
    u.email = 'user@example.org'
    assert !u.save

    u.username = nil
    u.email = 'user@example.org'
    u.password = 'some weird password'
    assert !u.save

  end

  test "user should save and destroy" do
    u = FactoryGirl.build(:cf_user)

    assert u.save
    assert_equal CfUser.all.length, 1

    assert u.destroy
    assert_equal CfUser.all.length, 0
  end

end


# eof