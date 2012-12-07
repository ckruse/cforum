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

  test "tags threads relation" do
    t = FactoryGirl.create(:cf_thread)
    tag = CfTag.new

    assert tag.tags_threads.empty?
    assert tag.threads.empty?

    tag.forum_id = t.forum.forum_id
    tag.tag_name = 'Rebellion'
    assert tag.save

    ctt = CfTagThread.create(tag_id: tag.tag_id, thread_id: t.thread_id)

    tag.threads.reload
    assert !tag.threads.empty?
    assert_equal tag.threads.length, 1

    assert !tag.tags_threads.empty?
    assert_equal tag.tags_threads.length, 1

    assert tag.tags_threads.clear
    assert_equal tag.threads.count(), 0
    assert_equal tag.tags_threads.count(), 0
  end

end


# eof
