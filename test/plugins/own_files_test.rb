# -*- coding: utf-8 -*-

require 'test_helper'

class OwnFilesTest < ActionController::TestCase
  # def setup
  #   @controller = CfMessagesController.new
  # end

  test "forums: shouldn't do anything for anonymous" do
    @controller = CfForumsController.new

    get :index

    assert_response :success
    assert_nil assigns(:own_css_file)
    assert_nil assigns(:own_js_file)
    assert_nil assigns(:own_css)
    assert_nil assigns(:own_js)
  end

  test "forums: should set file for forums index" do
    @controller = CfForumsController.new

    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css_file' => 'http://aldebaran.planet/z-rebellion.css', 'own_js_file' => 'http://aldebaran.planet/z-rebellion.js'})

    sign_in user

    get :index

    assert_response :success
    assert_not_nil assigns(:own_css_file)
    assert_not_nil assigns(:own_js_file)

    assert_equal 'http://aldebaran.planet/z-rebellion.css', assigns(:own_css_file)
    assert_equal 'http://aldebaran.planet/z-rebellion.js', assigns(:own_js_file)
  end

  test "forums: should set css and js for forums index" do
    @controller = CfForumsController.new

    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css' => '-css-code-', 'own_js' => '-js-code-'})

    sign_in user

    get :index

    assert_response :success
    assert_not_nil assigns(:own_css)
    assert_not_nil assigns(:own_js)

    assert_equal '-css-code-', assigns(:own_css)
    assert_equal '-js-code-', assigns(:own_js)
  end



  test "threads: shouldn't do anything for anonymous" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)

    get :index, curr_forum: forum.slug

    assert_response :success
    assert_nil assigns(:own_css_file)
    assert_nil assigns(:own_js_file)
    assert_nil assigns(:own_css)
    assert_nil assigns(:own_js)
  end

  test "threads: should set file for threads index" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css_file' => 'http://aldebaran.planet/z-rebellion.css', 'own_js_file' => 'http://aldebaran.planet/z-rebellion.js'})

    sign_in user

    get :index, curr_forum: forum.slug

    assert_response :success
    assert_not_nil assigns(:own_css_file)
    assert_not_nil assigns(:own_js_file)

    assert_equal 'http://aldebaran.planet/z-rebellion.css', assigns(:own_css_file)
    assert_equal 'http://aldebaran.planet/z-rebellion.js', assigns(:own_js_file)
  end

  test "threads: should set css and js for threads index" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css' => '-css-code-', 'own_js' => '-js-code-'})

    sign_in user

    get :index, curr_forum: forum.slug

    assert_response :success
    assert_not_nil assigns(:own_css)
    assert_not_nil assigns(:own_js)

    assert_equal '-css-code-', assigns(:own_css)
    assert_equal '-js-code-', assigns(:own_js)
  end

  test "threads: new: shouldn't do anything for anonymous" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)

    get :new, curr_forum: forum.slug

    assert_response :success
    assert_nil assigns(:own_css_file)
    assert_nil assigns(:own_js_file)
    assert_nil assigns(:own_css)
    assert_nil assigns(:own_js)
  end

  test "threads: new: should set file for threads index" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css_file' => 'http://aldebaran.planet/z-rebellion.css', 'own_js_file' => 'http://aldebaran.planet/z-rebellion.js'})

    sign_in user

    get :new, curr_forum: forum.slug

    assert_response :success
    assert_not_nil assigns(:own_css_file)
    assert_not_nil assigns(:own_js_file)

    assert_equal 'http://aldebaran.planet/z-rebellion.css', assigns(:own_css_file)
    assert_equal 'http://aldebaran.planet/z-rebellion.js', assigns(:own_js_file)
  end

  test "threads: new: should set css and js for threads index" do
    @controller = CfThreadsController.new

    forum = FactoryGirl.create(:cf_write_forum)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css' => '-css-code-', 'own_js' => '-js-code-'})

    sign_in user

    get :new, curr_forum: forum.slug

    assert_response :success
    assert_not_nil assigns(:own_css)
    assert_not_nil assigns(:own_js)

    assert_equal '-css-code-', assigns(:own_css)
    assert_equal '-js-code-', assigns(:own_js)
  end



  test "messages: shouldn't do anything for anonymous" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)

    get :show, to_params_hash(message)

    assert_response :success
    assert_nil assigns(:own_css_file)
    assert_nil assigns(:own_js_file)
    assert_nil assigns(:own_css)
    assert_nil assigns(:own_js)
  end

  test "messages: should set file for show" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css_file' => 'http://aldebaran.planet/z-rebellion.css', 'own_js_file' => 'http://aldebaran.planet/z-rebellion.js'})

    sign_in user

    get :show, to_params_hash(message)

    assert_response :success
    assert_not_nil assigns(:own_css_file)
    assert_not_nil assigns(:own_js_file)

    assert_equal 'http://aldebaran.planet/z-rebellion.css', assigns(:own_css_file)
    assert_equal 'http://aldebaran.planet/z-rebellion.js', assigns(:own_js_file)
  end

  test "messages: should set css and js for show" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css' => '-css-code-', 'own_js' => '-js-code-'})

    sign_in user

    get :show, to_params_hash(message)

    assert_response :success
    assert_not_nil assigns(:own_css)
    assert_not_nil assigns(:own_js)

    assert_equal '-css-code-', assigns(:own_css)
    assert_equal '-js-code-', assigns(:own_js)
  end

  test "messages: new: shouldn't do anything for anonymous" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)

    get :new, to_params_hash(message)

    assert_response :success
    assert_nil assigns(:own_css_file)
    assert_nil assigns(:own_js_file)
    assert_nil assigns(:own_css)
    assert_nil assigns(:own_js)
  end

  test "messages: new: should set file for show" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css_file' => 'http://aldebaran.planet/z-rebellion.css', 'own_js_file' => 'http://aldebaran.planet/z-rebellion.js'})

    sign_in user

    get :new, to_params_hash(message)

    assert_response :success
    assert_not_nil assigns(:own_css_file)
    assert_not_nil assigns(:own_js_file)

    assert_equal 'http://aldebaran.planet/z-rebellion.css', assigns(:own_css_file)
    assert_equal 'http://aldebaran.planet/z-rebellion.js', assigns(:own_js_file)
  end

  test "messages: new: should set css and js for show" do
    @controller = CfMessagesController.new

    message = FactoryGirl.create(:cf_message)
    user = FactoryGirl.create(:cf_user)
    CfSetting.create!(user_id: user.user_id, options: {'own_css' => '-css-code-', 'own_js' => '-js-code-'})

    sign_in user

    get :new, to_params_hash(message)

    assert_response :success
    assert_not_nil assigns(:own_css)
    assert_not_nil assigns(:own_js)

    assert_equal '-css-code-', assigns(:own_css)
    assert_equal '-js-code-', assigns(:own_js)
  end

end

# eof