# -*- coding: utf-8 -*-

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should show index even if anonym" do
    u = FactoryGirl.create(:cf_user, admin: false)

    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_not_empty assigns(:users)
  end

  test "should show empty index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_empty assigns(:users)
  end

  test "should list only this user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user, username: 'lea', admin: false)

    get :index, s: 'lea'
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).length
    assert_equal 'lea', assigns(:users).first.username
  end


  test "should show user" do
    u = FactoryGirl.create(:cf_user, admin: false)

    get :show, id: u.username
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test "should not show nonexistant user" do
    assert_raise ActiveRecord::RecordNotFound do
      get :show, id: 'lea'
    end
  end

  test "should show user and warning for unconfirmed user" do
    u = FactoryGirl.create(:cf_user, admin: false, confirmed_at: nil, unconfirmed_email: nil)
    sign_in u

    get :show, id: u.username
    assert_response :success
    assert_not_nil flash[:error]
  end

  test "should show user and no warning because of other user for unconfirmed user" do
    u = FactoryGirl.create(:cf_user, admin: false, confirmed_at: nil, unconfirmed_email: nil)
    u1 = FactoryGirl.create(:cf_user, admin: false)
    sign_in u1

    get :show, id: u.username
    assert_response :success
    assert_nil flash[:error]
  end

  test "should show user and no warning because of anonymous user for unconfirmed user" do
    u = FactoryGirl.create(:cf_user, admin: false, confirmed_at: nil, unconfirmed_email: nil)

    get :show, id: u.username
    assert_response :success
    assert_nil flash[:error]
  end


  test "should not show edit form because of anonymous" do
    u = FactoryGirl.create(:cf_user, admin: false)

    assert_raise CForum::ForbiddenException do
      get :edit, id: u.username
    end
  end

  test "should not show edit form because of wrong user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user, admin: false)
    sign_in u1

    assert_raise CForum::ForbiddenException do
      get :edit, id: u.username
    end
  end

  test "should not show edit form because unconfirmed" do
    u = FactoryGirl.create(:cf_user, admin: false, confirmed_at: nil, unconfirmed_email: nil)
    sign_in u

    get :edit, id: u.username
    assert_redirected_to user_url(u)
  end

  test "should not show edit form because unconfirmed even if admin because same user" do
    u = FactoryGirl.create(:cf_user, confirmed_at: nil, unconfirmed_email: nil)
    sign_in u

    get :edit, id: u.username
    assert_redirected_to user_url(u)
  end

  test "should show edit form for unconfirmed because of admin" do
    u = FactoryGirl.create(:cf_user, admin: false, confirmed_at: nil, unconfirmed_email: nil)
    u1 = FactoryGirl.create(:cf_user)
    sign_in u1

    get :edit, id: u.username
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test "should show edit form" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    get :edit, id: u.username
    assert_response :success
    assert_not_nil assigns(:user)
  end

  test "should show edit form as admin" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user)
    sign_in u1

    get :edit, id: u.username
    assert_response :success
    assert_not_nil assigns(:user)
  end


  test "should not update because of anonymous" do
    u = FactoryGirl.create(:cf_user, admin: false)

    assert_raise CForum::ForbiddenException do
      post :update, id: u.username, cf_user: {username: 'lulu'}
    end
  end

  test "should not update because of wrong user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user, admin: false)
    sign_in u1

    assert_raise CForum::ForbiddenException do
      post :update, id: u.username, cf_user: {username: 'lulu'}
    end
  end

  test "should update because of admin" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user, admin: true)
    sign_in u1

    post :update, id: u.username, cf_user: {username: 'lulu'}
    assert_redirected_to edit_user_path(u.reload)
  end

  test "should update because of right user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    post :update, id: u.username, cf_user: {username: 'lulu'}
    assert_redirected_to edit_user_path(u.reload)
  end

  test "should not update because of invalid" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    post :update, id: u.username, cf_user: {password: 'l'}
    assert_response :success
    assert_not_nil assigns(:user)
  end


  test "should not destroy because of anonymous" do
    u = FactoryGirl.create(:cf_user, admin: false)

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: u.username
    end
  end

  test "should not destroy because of wrong user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user, admin: false)
    sign_in u1

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: u.username
    end
  end

  test "should destroy because of right user" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    assert_difference 'CfUser.count', -1 do
      delete :destroy, id: u.username
    end
    assert_redirected_to root_url()
  end

  test "should destroy because of admin" do
    u = FactoryGirl.create(:cf_user, admin: false)
    u1 = FactoryGirl.create(:cf_user)
    sign_in u1

    assert_difference 'CfUser.count', -1 do
      delete :destroy, id: u.username
    end
    assert_redirected_to root_url()
  end

end

# eof
