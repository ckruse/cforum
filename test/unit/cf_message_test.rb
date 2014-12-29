# -*- coding: utf-8 -*-

require 'test_helper'

class CfMessageTest < ActiveSupport::TestCase
  test "validations" do
    m = CfMessage.new
    assert !m.save

    m.subject = 'Down with the Imperium!'
    assert !m.save

    m.content = Faker::Lorem.paragraphs.join("\n\n")
    assert !m.save

    m.author = 'Luke'
    assert !m.save

    t = FactoryGirl.create(:cf_thread)
    m.thread_id = t.thread_id

    assert !m.save

    m.subject = nil
    m.forum_id = t.forum_id
    assert !m.save

    m.subject = 'a'
    assert !m.save

    m.subject = 'Down with the Imperium!'
    m.author = 'a'
    assert !m.save

    m.author = 'Luke'
    m.content = 'a'
    assert !m.save

    m.content = Faker::Lorem.paragraphs.join("\n\n")
    m.email = '24234'
    assert !m.save

    m.email = 'a'
    assert !m.save

    m.email = 'luke@rebellion.gov'
    m.homepage = 'a'
    assert !m.save

    m.homepage = 'wefwef'
    assert !m.save

    m.homepage = 'http://heise.de/'
    assert m.save
  end

  test "thread association" do
    m = FactoryGirl.create(:cf_message)
    assert_not_nil m.thread
  end

  test "forum association" do
    m = FactoryGirl.create(:cf_message)
    assert_not_nil m.forum
  end

  test "owner association" do
    m = FactoryGirl.create(:cf_message)
    assert_not_nil m.owner
  end

  test "delete and restore" do
    m = FactoryGirl.create(:cf_message)
    m1 = FactoryGirl.create(:cf_message, forum: m.forum, thread: m.thread, parent_id: m.message_id)

    t = CfThread.preload(:messages).find(m.thread.thread_id)
    t.gen_tree

    t.sorted_messages[0].delete_with_subtree
    assert m.reload.deleted
    assert m1.reload.deleted

    t.sorted_messages[0].restore_with_subtree
    assert !m.reload.deleted
    assert !m.reload.deleted

    t.sorted_messages[1].delete_with_subtree
    assert !m.reload.deleted
    assert m1.reload.deleted

    t.sorted_messages[1].restore_with_subtree
    assert !m.reload.deleted
    assert !m.reload.deleted
  end

  test "tags associations" do
    msg = FactoryGirl.create(:cf_message)
    tag = CfTag.create!(tag_name: 'death star', forum_id: msg.forum_id)

    assert_equal 0, msg.messages_tags.count()
    assert_equal 0, msg.tags.count()

    CfMessageTag.create!(tag_id: tag.tag_id, message_id: msg.message_id)
    assert_equal 1, msg.messages_tags.count()
    assert_equal 1, msg.tags.count()

    assert msg.tags.clear
    assert_equal 0, msg.tags.count()
    assert_equal 0, msg.messages_tags.count()
    assert_not_nil CfTag.find_by_tag_id tag.tag_id
  end

  test "flag with subtree" do
    msg1 = FactoryGirl.create(:cf_message)
    msg2 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)

    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    t.message.flag_with_subtree('test_flag', 'test_value')

    msg1.reload
    msg2.reload

    assert_equal 'test_value', msg1.flags['test_flag']
    assert_equal 'test_value', msg2.flags['test_flag']
  end

  test "flag with subtree shouldn't flag sibling" do
    msg1 = FactoryGirl.create(:cf_message)
    msg2 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)
    msg3 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg2.message_id)
    msg4 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)

    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    t.message.messages[0].flag_with_subtree('test_flag', 'test_value')

    msg1.reload
    msg2.reload
    msg3.reload
    msg4.reload

    assert_nil msg1.flags['test_flag']
    assert_nil msg1.flags['test_flag']
    assert_equal 'test_value', msg2.flags['test_flag']
    assert_equal 'test_value', msg3.flags['test_flag']
  end

  test "del flag with subtree" do
    msg1 = FactoryGirl.create(:cf_message)
    msg2 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)

    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    t.message.flag_with_subtree('test_flag', 'test_value')

    msg1.reload
    msg2.reload

    assert_equal 'test_value', msg1.flags['test_flag']
    assert_equal 'test_value', msg2.flags['test_flag']

    t.reload
    t.gen_tree

    t.message.del_flag_with_subtree('test_flag')

    msg1.reload
    msg2.reload

    assert_nil msg1.flags['test_flag']
    assert_nil msg2.flags['test_flag']
  end

  test "del flag with subtree shouldn't del flag on sibling" do
    msg1 = FactoryGirl.create(:cf_message)
    msg2 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)
    msg3 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg2.message_id)
    msg4 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id)


    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    t.message.flag_with_subtree('test_flag', 'test_value')

    msg1.reload
    msg2.reload
    msg3.reload
    msg4.reload

    assert_equal 'test_value', msg1.flags['test_flag']
    assert_equal 'test_value', msg2.flags['test_flag']
    assert_equal 'test_value', msg3.flags['test_flag']
    assert_equal 'test_value', msg4.flags['test_flag']

    t.reload
    t.gen_tree

    t.message.messages[0].del_flag_with_subtree('test_flag')

    msg1.reload
    msg2.reload
    msg3.reload
    msg4.reload

    assert_equal 'test_value', msg1.flags['test_flag']
    assert_equal 'test_value', msg4.flags['test_flag']
    assert_nil msg2.flags['test_flag']
    assert_nil msg3.flags['test_flag']
  end

  test "should be open" do
    msg = FactoryGirl.create(:cf_message)
    assert msg.open?
  end

  test "should not be open due to vote" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer'] = 'yes'

    assert !msg.open?
  end

  test "should not be open due to admin decision" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer-admin'] = 'yes'

    assert !msg.open?
  end

  test "should be open due to vote" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer'] = 'no'

    assert msg.open?
  end

  test "should be open due to admin decision" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer-admin'] = 'no'

    assert msg.open?
  end

  test "should not be open despite vote due to admin decision" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer-admin'] = 'yes'
    msg.flags['no-answer'] = 'no'

    assert !msg.open?
  end

  test "should be open despite vote due to admin decision" do
    msg = FactoryGirl.create(:cf_message)
    msg.flags['no-answer-admin'] = 'no'
    msg.flags['no-answer'] = 'yes'

    assert msg.open?
  end

  test "subject should be changed" do
    msg1 = FactoryGirl.create(:cf_message, subject: 'Subject 1')
    FactoryGirl.create(:cf_message,
                       thread_id: msg1.thread_id,
                       parent_id: msg1.message_id,
                       subject: 'Subject 2')

    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    assert t.message.messages[0].subject_changed?
  end

  test "subject should not be changed" do
    msg1 = FactoryGirl.create(:cf_message, subject: 'Subject 1')
    FactoryGirl.create(:cf_message,
                       thread_id: msg1.thread_id,
                       parent_id: msg1.message_id,
                       subject: 'Subject 1')

    t = CfThread.find(msg1.thread_id)
    t.gen_tree

    assert !t.message.messages[0].subject_changed?
  end

  test "subject_changed shouldn't fail on thread message" do
    msg = FactoryGirl.create(:cf_message)
    assert_nothing_raised do
      assert !msg.subject_changed?
    end
  end

  test "subject_changed should fetch parent automatically" do
    msg1 = FactoryGirl.create(:cf_message, subject: 'Subject 1')
    msg2 = FactoryGirl.create(:cf_message,
                              thread_id: msg1.thread_id,
                              parent_id: msg1.message_id,
                              subject: 'Subject 2')

    assert_nothing_raised do
      assert msg2.subject_changed?
    end

  end
end


# eof
