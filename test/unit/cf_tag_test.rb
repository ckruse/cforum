# -*- coding: utf-8 -*-

require 'test_helper'

class CfTagTest < ActiveSupport::TestCase
  test "test validations" do
    f = FactoryGirl.create(:cf_forum)
    t = CfTag.new

    assert !t.save

    t.forum_id = f.forum_id
    assert !t.save

    t.tag_name = 'a'
    assert !t.save

    t.tag_name = 'luke' * 50
    assert !t.save

    t.tag_name = 'Rebellion'
    assert t.save
  end

  test "forum relation" do
    f = FactoryGirl.create(:cf_forum)
    t = CfTag.new(tag_name: 'Rebellion')

    assert_nil t.forum

    t.forum_id = f.forum_id
    t.save

    assert_not_nil t.forum
    assert_equal t.forum.forum_id, f.forum_id
  end

  test "tags messages relation" do
    msg = FactoryGirl.create(:cf_message)
    tag = CfTag.new

    assert tag.messages_tags.empty?
    assert tag.messages.empty?

    tag.forum_id = msg.forum.forum_id
    tag.tag_name = 'Rebellion'
    assert tag.save

    cmt = CfMessageTag.create(tag_id: tag.tag_id, message_id: msg.message_id)

    tag.messages.reload
    assert !tag.messages.empty?
    assert_equal tag.messages.length, 1

    assert !tag.messages_tags.empty?
    assert_equal tag.messages_tags.length, 1

    assert tag.messages_tags.clear
    assert_equal tag.messages.count(), 0
    assert_equal tag.messages_tags.count(), 0
  end

  test "to_param should be equal to slug" do
    t = FactoryGirl.create(:cf_tag)
    assert_equal t.slug, t.to_param
  end

end


# eof
