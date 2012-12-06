# -*- coding: utf-8 -*-

require 'test_helper'

class CfSettingTest < ActiveSupport::TestCase
  test "should create global setting" do
    s = CfSetting.create(
      options: {'nam' => 'val'}
    )

    assert_not_nil s
    assert !s.new_record?

    s1 = CfSetting.where(user_id: nil, forum_id: nil, setting_id: s.setting_id).first
    assert_not_nil s1
    assert_equal s.setting_id, s1.setting_id
    assert_equal 'val', s1.options['nam']
  end

  test "should count setting" do
    FactoryGirl.create(:cf_setting)
    FactoryGirl.create(:cf_setting)

    assert_equal 2, CfSetting.count()
  end

  test "should create and destroy" do
    s = FactoryGirl.create(:cf_setting)
    assert_not_nil CfSetting.find_by_setting_id(s.setting_id)

    s.destroy
    assert_nil CfSetting.find_by_setting_id(s.setting_id)
  end

  test "should create user setting" do
    u = FactoryGirl.create(:cf_user)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      user_id: u.user_id
    )

    assert_not_nil s
    assert !s.new_record?

    s1 = CfSetting.where(user_id: u.user_id, forum_id: nil, setting_id: s.setting_id).first
    assert_not_nil s1
    assert_equal s.setting_id, s1.setting_id
    assert_equal 'val', s1.options['nam']
  end

  test "should create forum setting" do
    f = FactoryGirl.create(:cf_forum)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      forum_id: f.forum_id
    )

    assert_not_nil s
    assert !s.new_record?

    s1 = CfSetting.where(user_id: nil, forum_id: f.forum_id, setting_id: s.setting_id).first
    assert_not_nil s1
    assert_equal s.setting_id, s1.setting_id
    assert_equal 'val', s1.options['nam']
  end

  test "should create user-forum setting" do
    f = FactoryGirl.create(:cf_forum)
    u = FactoryGirl.create(:cf_user)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      forum_id: f.forum_id,
      user_id: u.user_id
    )

    assert_not_nil s
    assert !s.new_record?

    s1 = CfSetting.where(
      user_id: u.user_id,
      forum_id: f.forum_id,
      setting_id: s.setting_id
    ).first

    assert_not_nil s1
    assert_equal s.setting_id, s1.setting_id
    assert_equal 'val', s1.options['nam']
  end

  test "should not have forum" do
    s = CfSetting.create(
      options: {'nam' => 'val'}
    )

    assert_nil s.forum

    u = FactoryGirl.create(:cf_user)
    s.user_id = u.user_id
    s.save

    assert_nil s.forum
  end

  test "should have forum" do
    f = FactoryGirl.create(:cf_forum)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      forum_id: f.forum_id
    )

    assert_not_nil s.forum

    u = FactoryGirl.create(:cf_user)
    s.user_id = u.user_id
    s.save

    assert_not_nil s.forum
  end

  test "should have user" do
    u = FactoryGirl.create(:cf_user)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      user_id: u.user_id
    )

    assert_not_nil s.user

    f = FactoryGirl.create(:cf_forum)
    s.forum_id = f.forum_id
    s.save

    assert_not_nil s.user
  end

  test "should have both user and forum" do
    u = FactoryGirl.create(:cf_user)
    f = FactoryGirl.create(:cf_forum)
    s = CfSetting.create(
      options: {'nam' => 'val'},
      user_id: u.user_id,
      forum_id: f.forum_id
    )

    assert_not_nil s.user
    assert_not_nil s.forum
  end

  test "user_id and forum_id combination should be unique" do
    u = FactoryGirl.create(:cf_user)
    f = FactoryGirl.create(:cf_forum)

    s = CfSetting.create(user_id: u.user_id, forum_id: f.forum_id)
    assert_not_nil s

    saved = false
    begin
      s1 = CfSetting.create(user_id: u.user_id, forum_id: f.forum_id)
      saved = true
    rescue ActiveRecord::RecordNotUnique
    end

    assert !saved

    s.forum_id = nil
    s.save

    saved = false
    begin
      s1 = CfSetting.create(user_id: u.user_id)
      saved = true
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.message =~ /Uniqueness violation on column id/
    end

    assert !saved

    s.forum_id = f.forum_id
    s.user_id = nil
    s.save

    saved = false
    begin
      s1 = CfSetting.create(forum_id: f.forum_id)
      saved = true
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.message =~ /Uniqueness violation on column id/
    end

    assert !saved
  end

end


# eof
