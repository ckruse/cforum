# -*- coding: utf-8 -*-

require 'test_helper'

class CfNotificationTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  test "notification should not save without subject, body and recipient_id" do
    u = FactoryGirl.create(:cf_user)

    n = CfNotification.new()
    assert !n.save

    n.subject = 'Just some text'
    assert !n.save

    n.body = "Lorem ipsum"
    assert !n.save

    n.recipient_id = u.user_id
    assert n.save
  end

  test "priv message should save and destroy" do
    n = FactoryGirl.build(:cf_notification)

    assert_difference 'CfNotification.count' do
      assert n.save
    end

    assert_difference 'CfNotification.count', -1 do
      assert n.destroy
    end
  end

  test "minimum and maximum length of subject" do
    n = FactoryGirl.build(:cf_notification)

    n.subject = n.subject * 250
    assert !n.save

    n.subject = 'l'
    assert !n.save
  end

  test "minimum and maximum length of body" do
    n = FactoryGirl.build(:cf_notification)

    n.body = n.body * 12288
    assert !n.save

    n.body = 'l'
    assert !n.save
  end
end


# eof
