# -*- coding: utf-8 -*-

require 'test_helper'

class CfThreadTest < ActiveSupport::TestCase
  test "should not save" do
    f = FactoryGirl.create(:cf_forum)
    t = CfThread.new

    assert !t.save

    t.slug = 'Luke'
    assert !t.save

    t.slug = 'luke'
    assert !t.save

    t.slug = nil
    t.forum_id = f.forum_id
    assert !t.save
  end

  test "should save" do
    f = FactoryGirl.create(:cf_forum)
    t = CfThread.new

    t.slug = 'luke'
    t.forum_id = f.forum_id
    assert t.save
  end

  test "messages relation" do
    t = FactoryGirl.create(:cf_thread)
    m = FactoryGirl.create(:cf_message, owner: nil, forum: t.forum, thread: t)

    t = CfThread.find t.thread_id
    assert_equal 1, t.messages.count()

    m1 = FactoryGirl.create(:cf_message, owner: nil, forum: t.forum, thread: t, parent_id: m.message_id)

    t = CfThread.includes(:messages).find t.thread_id
    assert_equal 2, t.messages.count()
    assert_equal t.message.message_id, m.message_id
    assert_equal t.messages[0].messages[0].message_id, m1.message_id

    assert_equal m, t.find_message(m.message_id)
    assert_nil t.find_message(-324234)

    assert_equal m, t.find_message!(m.message_id)

    not_found = false
    begin
      t.find_message!(-303234)
    rescue CForum::NotFoundException
      not_found = true
    end

    assert not_found

    m.mid = 1
    m.save
    m1.mid = 2
    m1.save

    t = CfThread.includes(:messages).find t.thread_id

    assert_equal m, t.find_by_mid(m.mid)
    assert_nil t.find_by_mid(-234234)

    assert_equal m, t.find_by_mid!(m.mid)

    not_found = false
    begin
      t.find_by_mid!(-234234)
    rescue CForum::NotFoundException
      not_found = true
    end

    assert not_found
  end

end


# eof
