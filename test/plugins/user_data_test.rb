# -*- coding: utf-8 -*-

require 'test_helper'

class UserDataTest < ActionController::TestCase

  test "set nothin in new message because of anonymous and no cookie values" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message)

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    assert_nil assigns(:message).author
    assert_nil assigns(:message).email
    assert_nil assigns(:message).homepage
  end

  test "set name, email and homepage in new message because of anonymous and cookie values" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message)

    @request.cookies[:cforum_author] = 'Yoda'
    @request.cookies[:cforum_email] = 'yoda@jedis.gov'
    @request.cookies[:cforum_homepage] = 'http://jedis.gov/yoda'

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    assert_equal 'Yoda', assigns(:message).author
    assert_equal 'yoda@jedis.gov', assigns(:message).email
    assert_equal 'http://jedis.gov/yoda', assigns(:message).homepage
  end

  test "set nothing in new message because of user wo config" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message)
    user    = FactoryGirl.create(:cf_user)

    sign_in user

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    assert_nil assigns(:message).author
    assert_nil assigns(:message).email
    assert_nil assigns(:message).homepage
  end

  test "set email and homepage in new message because of user" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message)
    user    = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'email' => 'yoda@jedis.gov',
        'url' => 'http://jedis.gov/yoda'
      }
    )

    sign_in user

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    assert_nil assigns(:message).author
    assert_equal 'yoda@jedis.gov', assigns(:message).email
    assert_equal 'http://jedis.gov/yoda', assigns(:message).homepage
  end

  test "set greeting, farewell and signature in new message because of user" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message)
    user    = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, Stranger,\n\n",
        'farewell' => "May the force be with you!\n",
        'signature' => 'Long live the republic!'
      }
    )

    sign_in user

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    txt = assigns(:message).content

    assert txt =~ /^Greetings, Stranger,\n\n/
    assert txt =~ /May the force be with you!\n/
    assert txt =~ /\n-- \nLong live the republic!/
  end

  test "set greeting with firstname in new message because of user" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message, author: 'Obi-Wan Kenobi')
    user    = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, {$vname},\n\n"
      }
    )

    sign_in user

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    txt = assigns(:message).content

    assert txt =~ /^Greetings, Obi-Wan,\n\n/
  end

  test "set greeting with full name in new message because of user" do
    @controller = CfMessagesController.new
    message = FactoryGirl.create(:cf_message, author: 'Obi-Wan Kenobi')
    user    = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, {$name},\n\n"
      }
    )

    sign_in user

    get :new, to_params_hash(message)

    assert_not_nil assigns(:message)
    txt = assigns(:message).content

    assert txt =~ /^Greetings, Obi-Wan Kenobi,\n\n/
  end


  #
  # threads
  #

  test "threads: set nothin in new message because of anonymous and no cookie values" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    assert_nil assigns(:thread).message.author
    assert_nil assigns(:thread).message.email
    assert_nil assigns(:thread).message.homepage
  end

  test "threads: set name, email and homepage in new message because of anonymous and cookie values" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)

    @request.cookies[:cforum_author] = 'Yoda'
    @request.cookies[:cforum_email] = 'yoda@jedis.gov'
    @request.cookies[:cforum_homepage] = 'http://jedis.gov/yoda'

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    assert_equal 'Yoda', assigns(:thread).message.author
    assert_equal 'yoda@jedis.gov', assigns(:thread).message.email
    assert_equal 'http://jedis.gov/yoda', assigns(:thread).message.homepage
  end

  test "threads: set nothing in new message because of user wo config" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)

    sign_in user

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    assert_nil assigns(:thread).message.author
    assert_nil assigns(:thread).message.email
    assert_nil assigns(:thread).message.homepage
  end

  test "threads: set email and homepage in new message because of user" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'email' => 'yoda@jedis.gov',
        'url' => 'http://jedis.gov/yoda'
      }
    )

    sign_in user

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    assert_nil assigns(:thread).message.author
    assert_equal 'yoda@jedis.gov', assigns(:thread).message.email
    assert_equal 'http://jedis.gov/yoda', assigns(:thread).message.homepage
  end

  test "threads: set greeting, farewell and signature in new message because of user" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, Stranger,\n\n",
        'farewell' => "May the force be with you!\n",
        'signature' => 'Long live the republic!'
      }
    )

    sign_in user

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    txt = assigns(:thread).message.content

    assert txt =~ /^Greetings, Stranger,\n\n/
    assert txt =~ /May the force be with you!\n/
    assert txt =~ /\n-- \nLong live the republic!/
  end

  test "threads: set greeting with firstname in new message because of user" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, {$vname},\n\n"
      }
    )

    sign_in user

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    txt = assigns(:thread).message.content

    assert txt =~ /^Greetings, alle,\n\n/
  end

  test "threads: set greeting with full name in new message because of user" do
    @controller = CfThreadsController.new
    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)

    CfSetting.create!(
      user_id: user.user_id,
      options: {
        'greeting' => "Greetings, {$name},\n\n"
      }
    )

    sign_in user

    get :new, curr_forum: forum.slug

    assert_not_nil assigns(:thread)
    txt = assigns(:thread).message.content

    assert txt =~ /^Greetings, alle,\n\n/
  end

end

# eof