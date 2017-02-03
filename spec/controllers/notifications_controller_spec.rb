require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  let(:notification) { create(:notification) }

  before(:each) { sign_in notification.recipient }

  describe 'GET #index' do
    it 'assigns all notifications as @notifications' do
      get :index
      expect(assigns(:notifications)).to eq([notification])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested notification as @notification' do
      get :show, params: { id: notification.to_param }
      expect(assigns(:notification)).to eq(notification)
    end

    it 'redirects to the object' do
      get :show, params: { id: notification.to_param }
      expect(response).to redirect_to(notification.path)
    end

    it 'marks the notification as read' do
      get :show, params: { id: notification.to_param }
      notification.reload
      expect(notification.is_read).to be true
    end
  end

  describe 'POST #update' do
    it 'redirects to the notifications index' do
      post :update, params: { id: notification.to_param }
      expect(response).to redirect_to(notifications_path)
    end

    it 'marks the notification as unread' do
      post :update, params: { id: notification.to_param }
      notification.reload
      expect(notification.is_read).to be false
    end
  end

  describe 'DELETE #destroy' do
    it 'redirects to the notifications index' do
      delete :destroy, params: { id: notification.to_param }
      expect(response).to redirect_to(notifications_path)
    end

    it 'destroys the notification' do
      expect do
        delete :destroy, params: { id: notification.to_param }
      end.to change(Notification, :count).by(-1)
    end
  end

  describe 'DELETE #batch_destroy' do
    it 'deletes more than one notification' do
      notification1 = create(:notification, recipient: notification.recipient)

      expect do
        delete :batch_destroy, params: { ids: [notification.to_param, notification1.to_param] }
      end.to change(Notification, :count).by(-2)
    end

    it 'redirects to the notifications index' do
      delete :batch_destroy, params: { ids: [notification.to_param] }
      expect(response).to redirect_to(notifications_path)
    end

    it "doesn't fail with empty IDs" do
      delete :batch_destroy, params: { ids: [] }
      expect(response).to redirect_to(notifications_path)
    end
  end
end
