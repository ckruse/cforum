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
    t.latest_message = DateTime.now
    assert t.save
  end

  test "messages relation" do
    t = FactoryGirl.create(:cf_thread)
    m = FactoryGirl.create(:cf_message, owner: nil, forum: t.forum, thread: t)

    t = CfThread.find t.thread_id
    t.gen_tree
    assert_equal 1, t.sorted_messages.count()

    m1 = FactoryGirl.create(:cf_message, owner: nil, forum: t.forum, thread: t, parent_id: m.message_id)

    t = CfThread.includes(:messages).find t.thread_id
    t.gen_tree
    assert_equal 2, t.sorted_messages.count()
    assert_equal m.message_id, t.message.message_id
    assert_equal m1.message_id, t.sorted_messages[0].messages[0].message_id

    assert_equal m, t.find_message(m.message_id)
    assert_nil t.find_message(-324234)

    assert_equal m, t.find_message!(m.message_id)

    assert_raise ActiveRecord::RecordNotFound do
      t.find_message!(-303234)
    end

    m.mid = 1
    m.save
    m1.mid = 2
    m1.save

    t = CfThread.includes(:messages).find t.thread_id

    assert_equal m, t.find_by_mid(m.mid)
    assert_nil t.find_by_mid(-234234)

    assert_equal m, t.find_by_mid!(m.mid)

    assert_raise ActiveRecord::RecordNotFound do
      t.find_by_mid!(-234234)
    end

    assert t.messages.clear
    assert_equal 0, t.messages.count()
  end

  test "make_id" do
    assert_equal '/2012/12/1/death-star', CfThread.make_id(year: '2012', mon: '12', day: '1', tid: 'death-star')
    assert_equal '/2012/12/1/death-star', CfThread.make_id('2012', '12', '1', 'death-star')
  end

  test "gen_id" do
    t = FactoryGirl.create(:cf_thread)
    m = FactoryGirl.create(:cf_message, subject: 'Death Star', forum: t.forum)
    t.message = m


    assert_equal DateTime.now.strftime("/%Y/%b/%d/").downcase + 'death-star', CfThread.gen_id(t)
  end

  test "acceptance_forbidden?" do
    msg = FactoryGirl.create(:cf_message)
    msg.thread.gen_tree

    assert msg.thread.acceptance_forbidden?(nil, nil)
    assert msg.thread.acceptance_forbidden?('', '')
    assert !msg.thread.acceptance_forbidden?(msg.owner, nil)

    adm = FactoryGirl.create(:cf_user)
    assert !msg.thread.acceptance_forbidden?(adm, nil)

    usr = FactoryGirl.create(:cf_user, admin: false)
    assert msg.thread.acceptance_forbidden?(usr, nil)

    msg.uuid = '1234'
    msg.save
    msg.reload
    msg.thread.gen_tree

    assert !msg.thread.acceptance_forbidden?(nil, '1234')
    assert msg.thread.acceptance_forbidden?(nil, '12345')
    assert msg.thread.acceptance_forbidden?(nil, nil)
    assert msg.thread.acceptance_forbidden?(nil, '')
    assert msg.thread.acceptance_forbidden?('', '')
  end

  test "should not generate empty slug" do
    thread = CfThread.new
    thread.created_at = Date.parse('2015-02-24')

    thread.message = CfMessage.new(subject: '您好！', created_at: thread.created_at)

    id = CfThread.gen_id(thread)
    assert_not_equal '/2015/feb/24/', id

    thread.message.subject = "Льаборэж чингюльищ кончэктэтюы"
    id = CfThread.gen_id(thread)
    assert_not_equal '/2015/feb/24/', id
  end
end


# eof
