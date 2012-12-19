# -*- coding: utf-8 -*-

require 'test_helper'

class CfPrivMessageTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  test "priv message should not save without subject, body, sender_id and recipient_id" do
    u = FactoryGirl.create(:cf_user)

    p = CfPrivMessage.new()
    assert !p.save

    p.subject = 'Just some text'
    assert !p.save

    p.body = "Lorem ipsum"
    assert !p.save

    p.sender_id = u.user_id
    assert !p.save

    p.recipient_id = u.user_id
    assert !p.save

    p.owner_id = u.user_id
    assert p.save
  end

  test "priv message should save and destroy" do
    p = FactoryGirl.build(:cf_priv_message)

    assert_difference 'CfPrivMessage.count' do
      assert p.save
    end

    assert_difference 'CfPrivMessage.count', -1 do
      assert p.destroy
    end
  end

  test "minimum and maximum length of subject" do
    p = FactoryGirl.build(:cf_priv_message)

    p.subject = p.subject * 250
    assert !p.save

    p.subject = 'l'
    assert !p.save
  end

  test "minimum and maximum length of body" do
    p = FactoryGirl.build(:cf_priv_message)

    p.body = p.body * 12288
    assert !p.save

    p.body = 'l'
    assert !p.save
  end
end


# eof
