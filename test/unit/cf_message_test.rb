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
end


# eof
