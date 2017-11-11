require 'rails_helper'

RSpec.describe BadgesController, type: :controller do
  describe 'GET #index' do
    it 'assigns all badges as @badges' do
      badge = create(:badge)
      get :index
      expect(assigns(:badges)).to eq([badge])
    end
  end

  describe 'GET #show' do
    let(:badge) { create(:badge) }

    it 'shows assigns the badge as @badge' do
      get :show, params: { slug: badge.to_param }
      expect(assigns(:badge)).to eq(badge)
    end

    it 'removes notification for users' do
      user = create(:user)
      sign_in user
      create(:notification, oid: badge.badge_id, otype: 'badge',
                            recipient_id: user.user_id, is_read: false)

      expect do
        get :show, params: { slug: badge.to_param }
      end.to change(Notification.where(is_read: false), :count).by(-1)
    end
  end
end

# eof
