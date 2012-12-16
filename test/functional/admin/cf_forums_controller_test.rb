# -*- coding: utf-8 -*-

require 'test_helper'

class Admin::CfForumsControllerTest < ActionController::TestCase
  test "index: should not answer because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "index: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "index: should answer with empty list" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :index
    assert_not_nil assigns(:forums)
    assert_blank assigns(:forums)
    assert_response :success
  end

  test "index: should answer with non-empty list" do
    forum = FactoryGirl.create(:cf_forum)
    forum1 = FactoryGirl.create(:cf_forum, :public => false)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :index
    assert_not_nil assigns(:forums)
    assert_equal 2, assigns(:forums).length
    assert_response :success
  end


  test "edit: should not show forum because of anonymous" do
    forum = FactoryGirl.create(:cf_forum)

    assert_raise CForum::ForbiddenException do
      get :edit, {id: forum.forum_id}
    end
  end

  test "edit: should not answer because of not an admin" do
    forum = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :edit, {id: forum.forum_id}
    end
  end

  test "edit: should answer" do
    forum = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :edit, {id: forum.forum_id}
    assert_not_nil assigns(:cf_forum)
    assert_response :success
  end

  test "edit: should not edit non-existant" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, {id: 3324}
    end
  end


  test "new: should not show forum because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :new
    end
  end

  test "new: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :new
    end
  end

  test "new: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :new
    assert_not_nil assigns(:cf_forum)
    assert_response :success
  end


  test "create: should not answer because of anonymous" do
    assert_raise CForum::ForbiddenException do
      post :create, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end
  end

  test "create: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      post :create, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end
  end

  test "create: should not answer because of invalid" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_no_difference 'CfForum.count' do
      post :create, cf_forum: {name: '', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end

    assert_not_nil assigns(:cf_forum)
    assert !assigns(:cf_forum).valid?
    assert_response :success
  end

  test "create: should create forum" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_difference 'CfForum.count' do
      post :create, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end

    assert_not_nil assigns(:cf_forum)
    assert_redirected_to edit_admin_forum_url(assigns(:cf_forum).forum_id)
  end


  test "update: should not answer because of anonymous" do
    f = FactoryGirl.create(:cf_forum)
    assert_raise CForum::ForbiddenException do
      post :update, id: f.forum_id, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end
  end

  test "update: should not answer because of not an admin" do
    f = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      post :update, id: f.forum_id, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}
    end
  end

  test "update: should not answer because of invalid" do
    f = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :update, id: f.forum_id, cf_forum: {name: '', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}

    f1 = CfForum.find f.forum_id

    assert_not_nil assigns(:cf_forum)
    assert !assigns(:cf_forum).valid?
    assert_equal f.attributes, f1.attributes
    assert_response :success
  end

  test "update: should create forum" do
    f = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :update, id: f.forum_id, cf_forum: {name: 'Test', short_name: 'Test', slug: 'test', :public => false, description: 'lala'}

    f1 = CfForum.find f.forum_id

    assert_not_nil assigns(:cf_forum)
    assert_not_equal f.attributes, f1.attributes
    assert_redirected_to edit_admin_forum_url(assigns(:cf_forum).forum_id)
  end


  test "destroy: should not answer because of anonymous" do
    f = FactoryGirl.create(:cf_forum)
    assert_raise CForum::ForbiddenException do
      delete :destroy, id: f.forum_id
    end
  end

  test "destroy: should not answer because of not an admin" do
    f = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: f.forum_id
    end
  end

  test "destroy: should not answer because of non-existant" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, id: 33312
    end
  end

  test "destroy: should destroy forum" do
    f = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_difference 'CfForum.count', -1 do
      delete :destroy, id: f.forum_id
    end


    assert_not_nil assigns(:cf_forum)
    assert_redirected_to admin_forums_url()
  end


  test "merge: should not show forum because of anonymous" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)

    assert_raise CForum::ForbiddenException do
      get :merge, id: f1.forum_id
    end
  end

  test "merge: should not answer because of not an admin" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :merge, id: f1.forum_id
    end
  end

  test "merge: should answer" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :merge, id: f1.forum_id
    assert_not_nil assigns(:forums)
    assert_response :success
  end


  test "do_merge: should not show forum because of anonymous" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)

    assert_raise CForum::ForbiddenException do
      post :do_merge, id: f1.forum_id, merge_with: f2.forum_id
    end
  end

  test "do_merge: should not answer because of not an admin" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      post :do_merge, id: f1.forum_id, merge_with: f2.forum_id
    end
  end

  test "do_merge: should answer" do
    f1 = FactoryGirl.create(:cf_forum)
    f2 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_difference 'CfForum.count', -1 do
      post :do_merge, id: f1.forum_id, merge_with: f2.forum_id
    end

    assert_not_nil assigns(:cf_forum)
    assert_redirected_to admin_forums_url
  end

  test "do_merge: should not merge because of invalid merge_with param" do
    f1 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_no_difference 'CfForum.count' do
      post :do_merge, id: f1.forum_id, merge_with: 33333
    end

    assert_not_nil assigns(:cf_forum)
    assert_not_nil assigns(:merge_with)
    assert_response :success
  end

  test "do_merge: should not merge because of missing merge_with param" do
    f1 = FactoryGirl.create(:cf_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_no_difference 'CfForum.count' do
      post :do_merge, id: f1.forum_id
    end

    assert_not_nil assigns(:cf_forum)
    assert_not_nil assigns(:merge_with)
    assert_response :success
  end

end

# eof