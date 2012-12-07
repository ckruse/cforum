# -*- coding: utf-8 -*-

require 'test_helper'

class CfTagThreadTest < ActiveSupport::TestCase
  test "test validations" do
    thread = FactoryGirl.create(:cf_thread)
    tag = CfTag.create!(forum_id: thread.forum_id, tag_name: 'Rebellion')

    tag_thread = CfTagThread.new
    assert !tag_thread.save

    tag_thread.thread_id = thread.thread_id
    assert !tag_thread.save

    tag_thread.tag_id = tag.tag_id
    tag_thread.thread_id = nil
    assert !tag_thread.save

    tag_thread.thread_id = thread.thread_id
    assert tag_thread.save
  end

  test "thread association" do
    thread = FactoryGirl.create(:cf_thread)
    tag = CfTag.create!(forum_id: thread.forum_id, tag_name: 'Rebellion')

    tag_thread = CfTagThread.new
    assert_nil tag_thread.tag

    tag_thread.attributes = {thread_id: thread.thread_id, tag_id: tag.tag_id}
    assert tag_thread.save
    assert_not_nil tag_thread.thread
  end

  test "tag association" do
    thread = FactoryGirl.create(:cf_thread)
    tag = CfTag.create!(forum_id: thread.forum_id, tag_name: 'Rebellion')

    tag_thread = CfTagThread.new
    assert_nil tag_thread.tag

    tag_thread.attributes = {thread_id: thread.thread_id, tag_id: tag.tag_id}
    assert tag_thread.save
    assert_not_nil tag_thread.tag
  end

end


# eof
