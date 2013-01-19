# -*- coding: utf-8 -*-

require 'test_helper'

class CfTagThreadTest < ActiveSupport::TestCase
  test "test validations" do
    message = FactoryGirl.create(:cf_message)
    tag = CfTag.create!(forum_id: message.forum_id, tag_name: 'Rebellion')

    message_tag = CfMessageTag.new
    assert !message_tag.save

    message_tag.message_id = message.message_id
    assert !message_tag.save

    message_tag.tag_id = tag.tag_id
    message_tag.message_id = nil
    assert !message_tag.save

    message_tag.message_id = message.message_id
    assert message_tag.save
  end

  test "message association" do
    message = FactoryGirl.create(:cf_message)
    tag = CfTag.create!(forum_id: message.forum_id, tag_name: 'Rebellion')

    message_tag = CfMessageTag.new
    assert_nil message_tag.tag

    message_tag.attributes = {message_id: message.message_id, tag_id: tag.tag_id}
    assert message_tag.save
    assert_not_nil message_tag.message
  end

  test "tag association" do
    message = FactoryGirl.create(:cf_message)
    tag = CfTag.create!(forum_id: message.forum_id, tag_name: 'Rebellion')

    message_tag = CfMessageTag.new
    assert_nil message_tag.tag

    message_tag.attributes = {message_id: message.message_id, tag_id: tag.tag_id}
    assert message_tag.save
    assert_not_nil message_tag.tag
  end

end


# eof
