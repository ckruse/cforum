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

  test "should do a batch destroy" do
    u  = FactoryGirl.create(:cf_user)
    n1 = FactoryGirl.create(:cf_notification, recipient: u)
    n2 = FactoryGirl.create(:cf_notification, recipient: u)
    n3 = FactoryGirl.create(:cf_notification, recipient: u)

    sign_in u

    assert_difference 'CfNotification.count', -3 do
      post :batch_destroy, ids: [n1.notification_id, n2.notification_id, n3.notification_id]
    end

    assert_redirected_to notifications_url
  end

  test "should not crash while batch destroying" do
    u  = FactoryGirl.create(:cf_user)

    sign_in u
    post :batch_destroy
    assert_redirected_to notifications_url
  end

  test "should not crash while batch destroying with wrong ids" do
    u  = FactoryGirl.create(:cf_user)

    n1 = FactoryGirl.create(:cf_notification)
    n2 = FactoryGirl.create(:cf_notification)
    n3 = FactoryGirl.create(:cf_notification)

    sign_in u

    assert_no_difference 'CfNotification.count' do
      post :batch_destroy, ids: [n1.notification_id, n2.notification_id, n3.notification_id]
    end

    assert_redirected_to notifications_url
  end

  test "should mark unread in update" do
    u  = FactoryGirl.create(:cf_user)
    n1 = FactoryGirl.create(:cf_notification, recipient: u,
                            is_read: true)

    sign_in u

    assert_no_difference 'CfNotification.count' do
      put :update, id: n1.notification_id
    end

    n1.reload

    assert n1.is_read == false
    assert_redirected_to notifications_url
  end

  test "should not mark unread in update when not owner" do
    u  = FactoryGirl.create(:cf_user)
    n1 = FactoryGirl.create(:cf_notification, is_read: true)

    sign_in u

    assert_no_difference 'CfNotification.count' do
      assert_raise ActiveRecord::RecordNotFound do
        put :update, id: n1.notification_id
      end
    end

    n1.reload

    assert n1.is_read
  end

end

# eof
