require 'rails_helper'

RSpec.describe Admin::ForumsController, type: :controller do
  let(:admin) { FactoryBot.create(:user_admin) }

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns all forums as @forums' do
      forum = create(:forum)
      get :index
      expect(assigns(:forums)).to eq([forum])
    end
  end

  describe 'GET #new' do
    it 'assigns a new forum as @forum' do
      get :new
      expect(assigns(:forum)).to be_a_new(Forum)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested forum as @forum' do
      forum = create(:forum)
      get :edit, params: { id: forum.forum_id }
      expect(assigns(:forum)).to eq(forum)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new forum' do
        expect do
          post :create, params: { forum: attributes_for(:forum) }
        end.to change(Forum, :count).by(1)
      end

      it 'assigns a newly created forum as @forum' do
        post :create, params: { forum: attributes_for(:forum) }
        expect(assigns(:forum)).to be_a(Forum)
        expect(assigns(:forum)).to be_persisted
      end

      it 'redirects to the forum' do
        post :create, params: { forum: attributes_for(:forum) }
        expect(response).to redirect_to(edit_admin_forum_url(assigns(:forum).forum_id))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns a newly created but unsaved forum as @forum' do
        post :create, params: { forum: invalid_attributes }
        expect(assigns(:forum)).to be_a_new(Forum)
      end

      it "re-renders the 'new' template" do
        post :create, params: { forum: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Foo 1' }
      end

      it 'updates the requested forum' do
        forum = create(:forum)
        put :update, params: { id: forum.forum_id, forum: new_attributes }
        forum.reload
        expect(forum.name).to eq 'Foo 1'
      end

      it 'assigns the requested forum as @forum' do
        forum = create(:forum)
        put :update, params: { id: forum.forum_id, forum: new_attributes }
        expect(assigns(:forum)).to eq(forum)
      end

      it 'redirects to the forum' do
        forum = create(:forum)
        put :update, params: { id: forum.forum_id, forum: new_attributes }
        expect(response).to redirect_to(edit_admin_forum_url(forum.forum_id))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns the forum as @forum' do
        forum = create(:forum)
        put :update, params: { id: forum.forum_id, forum: invalid_attributes }
        expect(assigns(:forum)).to eq(forum)
      end

      it "re-renders the 'edit' template" do
        forum = create(:forum)
        put :update, params: { id: forum.forum_id, forum: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested forum' do
      forum = create(:forum)
      expect do
        delete :destroy, params: { id: forum.forum_id }
      end.to change(Forum, :count).by(-1)
    end

    it 'redirects to the forums list' do
      forum = create(:forum)
      delete :destroy, params: { id: forum.forum_id }
      expect(response).to redirect_to(admin_forums_url)
    end
  end
end

# eof
