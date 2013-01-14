# -*- coding: utf-8 -*-

require 'test_helper'

class Admin::CfUsersControllerTest < ActionController::TestCase
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

  test "index: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :index
    assert_not_nil assigns(:users)
    assert_response :success
  end


  test "edit: should not answer because of anonymous" do
    usr = FactoryGirl.create(:cf_user)

    assert_raise CForum::ForbiddenException do
      get :edit, id: usr.user_id
    end
  end

  test "edit: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :edit, id: usr.user_id
    end
  end

  test "edit: should not answer because of non-existant user" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, id: 'wefwefewfwefefw'
    end
  end

  test "edit: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    get :edit, id: usr.user_id
    assert_not_nil assigns(:user)
    assert_response :success
  end


  test "new: should not answer because of anonymous" do
    usr = FactoryGirl.create(:cf_user)

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
    assert_not_nil assigns(:user)
    assert_response :success
  end


  test "create: should not answer because of anonymous" do
    usr = FactoryGirl.create(:cf_user)

    assert_raise CForum::ForbiddenException do
      post :create, cf_user: {username: 'lala', email: 'abc@example.org', password: 'ewfwefwef', password_confirm: 'ewfwefwef'}
    end
  end

  test "create: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      post :create, cf_user: {username: 'lala', email: 'abc@example.org', password: 'ewfwefwef', password_confirm: 'ewfwefwef'}
    end
  end

  test "create: should answer not answer because of invalid" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :create, cf_user: {username: 'lala', email: 'lululu', password: 'ewfwefwef', password_confirm: 'ewfwefwef'}
    assert_not_nil assigns(:user)
    assert_response :success
  end

  test "create: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :create, cf_user: {username: 'lala', email: 'abc@example.org', password: 'ewfwefwef', password_confirm: 'ewfwefwef'}
    assert_not_nil assigns(:user)
    assert_redirected_to edit_admin_user_url(assigns(:user))
  end


  test "update: should not answer because of anonymous" do
    usr = FactoryGirl.create(:cf_user)

    assert_raise CForum::ForbiddenException do
      post :update, id: usr.user_id, cf_user: {email: 'abc@example.org'}
    end
  end

  test "update: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    sign_in usr

    assert_raise CForum::ForbiddenException do
      post :update, id: usr.user_id, cf_user: {email: 'abc@example.org'}
    end
  end

  test "update: should answer not answer because of invalid" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :update, id: usr.user_id, cf_user: {email: 'lululu'}
    assert_not_nil assigns(:user)
    assert_response :success
  end

  test "update: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    post :update, id: usr.user_id, cf_user: {email: 'abc@example.org'}
    assert_not_nil assigns(:user)
    assert_redirected_to edit_admin_user_url(assigns(:user))
  end


  test "destroy: should not answer because of anonymous" do
    usr1 = FactoryGirl.create(:cf_user)

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: usr1.user_id
    end
  end

  test "destroy: should not answer because of not an admin" do
    usr = FactoryGirl.create(:cf_user, admin: false)
    usr1 = FactoryGirl.create(:cf_user)

    sign_in usr

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: usr1.user_id
    end
  end

  test "destroy: should answer not answer because of non-existant user" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, id: 'lulululu'
    end
  end

  test "destroy: should answer" do
    usr = FactoryGirl.create(:cf_user, admin: true)
    usr1 = FactoryGirl.create(:cf_user)
    sign_in usr

    delete :destroy, id: usr1.user_id
    assert_not_nil assigns(:user)
    assert_redirected_to admin_users_url()
  end
end

# eof
