require 'rails_helper'

RSpec.describe Admin::BadgesController, type: :controller do
  let(:admin) { FactoryBot.create(:user_admin) }

  let(:valid_attributes) do
    { name: 'Foo',
      badge_type: 'custom',
      badge_medal_type: 'bronze',
      slug: 'foo' }
  end

  let(:invalid_attributes) do
    { name: '' }
  end

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns all badges as @badge_groups' do
      badge = create(:badge)
      get :index
      expect(assigns(:badges)).to eq([badge])
    end
  end

  describe 'GET #new' do
    it 'assigns a new badge as @badge' do
      get :new
      expect(assigns(:badge)).to be_a_new(Badge)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested badge as @badge' do
      badge = create(:badge)
      get :edit, params: { id: badge.to_param }
      expect(assigns(:badge)).to eq(badge)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Badge' do
        expect do
          post :create, params: { badge: valid_attributes }
        end.to change(Badge, :count).by(1)
      end

      it 'assigns a newly created badge as @badge' do
        post :create, params: { badge: valid_attributes }
        expect(assigns(:badge)).to be_a(Badge)
        expect(assigns(:badge)).to be_persisted
      end

      it 'redirects to the badge' do
        post :create, params: { badge: valid_attributes }
        expect(response).to redirect_to(edit_admin_badge_url(assigns(:badge)))
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved badge_group as @badge_group' do
        post :create, params: { badge: invalid_attributes }
        expect(assigns(:badge)).to be_a_new(Badge)
      end

      it "re-renders the 'new' template" do
        post :create, params: { badge: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Foo 1', slug: 'foo-1' }
      end

      it 'updates the requested badge_group' do
        badge = Badge.create! valid_attributes
        put :update, params: { id: badge.to_param, badge: new_attributes }
        badge.reload
        expect(badge.name).to eq 'Foo 1'
        expect(badge.slug).to eq 'foo-1'
      end

      it 'assigns the requested badge as @badge' do
        badge = Badge.create! valid_attributes
        put :update, params: { id: badge.to_param, badge: valid_attributes }
        expect(assigns(:badge)).to eq(badge)
      end

      it 'redirects to the badge' do
        badge = Badge.create! valid_attributes
        put :update, params: { id: badge.to_param, badge: valid_attributes }
        expect(response).to redirect_to(edit_admin_badge_url(badge))
      end
    end

    context 'with invalid params' do
      it 'assigns the badge as @badge' do
        badge = Badge.create! valid_attributes
        put :update, params: { id: badge.to_param, badge: invalid_attributes }
        expect(assigns(:badge)).to eq(badge)
      end

      it "re-renders the 'edit' template" do
        badge = Badge.create! valid_attributes
        put :update, params: { id: badge.to_param, badge: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested badge' do
      badge = create(:badge)
      expect do
        delete :destroy, params: { id: badge.to_param }
      end.to change(Badge, :count).by(-1)
    end

    it 'redirects to the badge_groups list' do
      badge = create(:badge)
      delete :destroy, params: { id: badge.to_param }
      expect(response).to redirect_to(admin_badges_url)
    end
  end
end

# eof
