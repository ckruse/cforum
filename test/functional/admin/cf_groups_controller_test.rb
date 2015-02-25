# -*- coding: utf-8 -*-

require 'test_helper'

class Admin::CfGroupsControllerTest < ActionController::TestCase
  test "should not show index because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "should not show index because of insufficient rights" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "should show empty index" do
    u = FactoryGirl.create(:cf_user, admin: true)
    sign_in u

    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
    assert assigns(:groups).blank?
  end

  test "should show index" do
    u = FactoryGirl.create(:cf_user, admin: true)
    g = FactoryGirl.create(:cf_group)
    sign_in u

    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
    assert !assigns(:groups).blank?
  end

  test "should not show edit form because of anonymous" do
    g = FactoryGirl.create(:cf_group)

    assert_raise CForum::ForbiddenException do
      get :edit, id: g.group_id
    end
  end

  test "should not show edit form because of insufficient rights" do
    u = FactoryGirl.create(:cf_user, admin: false)
    g = FactoryGirl.create(:cf_group)

    sign_in u

    assert_raise CForum::ForbiddenException do
      get :edit, id: g.group_id
    end
  end

  test "should show edit form" do
    u = FactoryGirl.create(:cf_user, admin: true)
    g = FactoryGirl.create(:cf_group)

    sign_in u

    get :edit, id: g.group_id
    assert_response :success
    assert_not_nil assigns(:group)
  end

  test "should not update group because of anonymous" do
    g = FactoryGirl.create(:cf_group)

    assert_raise CForum::ForbiddenException do
      put :update, id: g.group_id, cf_group: {name: 'blah'}
    end
  end

  test "should not update group because of insufficient rights" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: false)

    sign_in u

    assert_raise CForum::ForbiddenException do
      put :update, id: g.group_id, cf_group: {name: 'blah'}
    end
  end

  test "should not update group because of invalid" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: true)

    sign_in u

    put :update, id: g.group_id, cf_group: {name: 'b'}
    assert_response :success
    assert_not_nil assigns(:group)
    assert !assigns(:group).valid?
  end

  test "should update group" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: true)

    sign_in u

    put :update, id: g.group_id, cf_group: {name: 'bububu'}
    assert_redirected_to edit_admin_group_url(g)
  end

  test "should update group with users" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: true)

    sign_in u

    put :update, id: g.group_id, cf_group: {name: 'bububu'}, users: [u.user_id]
    assert_redirected_to edit_admin_group_url(g)
  end

  test "should update group with users and forums" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: true)
    f = FactoryGirl.create(:cf_forum)

    sign_in u

    put :update, id: g.group_id, cf_group: {name: 'bububu'}, users: [u.user_id], forums: [f.forum_id, ''], permissions: ['read', '']
    assert_redirected_to edit_admin_group_url(g)
  end

  test "should not show new form because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :new
    end
  end

  test "should not show new form because of insufficient rights" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    assert_raise CForum::ForbiddenException do
      get :new
    end
  end

  test "should show new form" do
    u = FactoryGirl.create(:cf_user, admin: true)
    sign_in u

    get :new
    assert_response :success
    assert_not_nil assigns(:group)
  end


  test "should not create group because of anonymous" do
    assert_raise CForum::ForbiddenException do
      post :create, cf_group: {name: 'blah'}
    end
  end


  test "should not create group because of insufficient rights" do
    u = FactoryGirl.create(:cf_user, admin: false)
    sign_in u

    assert_raise CForum::ForbiddenException do
      post :create, cf_group: {name: 'blah'}
    end
  end

  test "should not create group because of invalid" do
    u = FactoryGirl.create(:cf_user, admin: true)
    sign_in u

    post :create, cf_group: {name: 'b'}
    assert_response :success
    assert_not_nil assigns(:group)
    assert !assigns(:group).valid?
  end

  test "should create group" do
    u = FactoryGirl.create(:cf_user, admin: true)
    sign_in u

    assert_difference 'CfGroup.count' do
      post :create, cf_group: {name: 'blahblah'}
    end

    assert_redirected_to edit_admin_group_url(assigns(:group))
  end

  test "should create group with users" do
    u = FactoryGirl.create(:cf_user, admin: true)
    sign_in u

    assert_difference 'CfGroup.count' do
      post :create, cf_group: {name: 'blahblah'}, users: [u.user_id]
    end

    assert_redirected_to edit_admin_group_url(assigns(:group))
  end

  test "should create group with users and forums" do
    u = FactoryGirl.create(:cf_user, admin: true)
    f = FactoryGirl.create(:cf_forum)
    sign_in u

    assert_difference 'CfGroup.count' do
      post :create, cf_group: {name: 'blahblah'}, users: [u.user_id], forums: [f.forum_id, ''], permissions: ['read', '']
    end

    assert_redirected_to edit_admin_group_url(assigns(:group))
  end

  test "should not destroy because of anonymous" do
    g = FactoryGirl.create(:cf_group)

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: g.group_id
    end
  end

  test "should not destroy because of insuficient permissions" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: false)

    sign_in u

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: g.group_id
    end
  end

  test "should destroy" do
    g = FactoryGirl.create(:cf_group)
    u = FactoryGirl.create(:cf_user, admin: true)

    sign_in u

    assert_difference 'CfGroup.count', -1 do
      delete :destroy, id: g.group_id
    end

    assert_redirected_to admin_groups_url
  end

end

# eof
