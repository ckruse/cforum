# -*- coding: utf-8 -*-

require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  test "should not show index because of anonymous" do
    assert_raise CForum::ForbiddenException do
      get :index
    end
  end

  test "should show empty index" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
    assert_empty assigns(:notifications)
  end

  test "should show index" do
    usr = FactoryGirl.create(:cf_user)
    notification = FactoryGirl.create(:cf_notification, recipient: usr)
    sign_in usr

    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
    assert_not_empty assigns(:notifications)
  end


  test "should not destroy notification because of anonymous" do
    notification = FactoryGirl.create(:cf_notification)

    assert_raise CForum::ForbiddenException do
      delete :destroy, id: notification.notification_id
    end
  end

  test "should not destroy notification because of non-existant notification" do
    usr = FactoryGirl.create(:cf_user)
    sign_in usr

    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, id: 2131312312312
    end
  end

  test "should destroy notification" do
    notification = FactoryGirl.create(:cf_notification)
    sign_in notification.recipient

    delete :destroy, id: notification.notification_id
    assert_redirected_to notifications_url
  end
end

# eof
