require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #index' do
    it 'assigns all users as @users' do
      user = create(:user)
      get :index
      expect(assigns(:users)).to eq([user])
    end

    it 'searches user with s param' do
      users = [create(:user), create(:user), create(:user)]
      get :index, params: { s: users.first.username }
      expect(assigns(:users)).to eq([users.first])
    end

    it 'searches users by nick and sorts by activity desc' do
      users = [create(:user), create(:user), create(:user)]
      get :index, params: { nick: users.first.username }
      expect(assigns(:users)).to eq([users.first])
      expect(assigns(:_sort_column)).to eq(:activity)
      expect(assigns(:_sort_direction)).to eq(:desc)
    end

    it 'searches exact with exact param' do
      users = [create(:user), create(:user), create(:user)]
      get :index, params: { exact: users.first.username }
      expect(assigns(:users)).to eq([users.first])
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user) }

    it 'shows assigns the user as @user' do
      get :show, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end

    it 'assigns messages by month as @messages_by_months' do
      get :show, params: { id: user.to_param }
      expect(assigns(:messages_by_months)).to eq([])
    end

    it 'assigns messages count as @messages_count' do
      get :show, params: { id: user.to_param }
      expect(assigns(:messages_count)).to eq(0)
    end

    it 'assigns the last messages as @last_messages' do
      get :show, params: { id: user.to_param }
      expect(assigns(:last_messages)).to eq([])
    end
  end

  describe 'GET #edit' do
    let(:user) { create(:user) }

    it 'assigns the requested user as @user' do
      sign_in user
      get :edit, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'PUT #update' do
    let(:user) { create(:user) }
    before(:each) { sign_in user }

    let(:new_attributes) do
      { username: 'Foo 1' }
    end

    let(:invalid_attributes) do
      { username: '' }
    end

    context 'with valid params' do
      it 'updates the requested user' do
        put :update, params: { id: user.to_param, user: new_attributes }
        user.reload
        expect(user.username).to eq 'Foo 1'
      end

      it 'assigns the requested user as @user' do
        put :update, params: { id: user.to_param, user: { username: user.username } }
        expect(assigns(:user)).to eq(user)
      end

      it 'redirects to the user' do
        put :update, params: { id: user.to_param, user: new_attributes }
        expect(response).to redirect_to(edit_user_url(user))
      end
    end

    context 'with invalid params' do
      it 'assigns the user as @user' do
        put :update, params: { id: user.to_param, user: invalid_attributes }
        expect(assigns(:user)).to eq(user)
      end

      it "re-renders the 'edit' template" do
        put :update, params: { id: user.to_param, user: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe '#confirm_destroy' do
    let(:user) { create(:user) }
    before(:each) { sign_in user }

    it 'assigns the user as @user' do
      get :confirm_destroy, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end

    it "renders the 'confirm_destroy' template" do
      get :confirm_destroy, params: { id: user.to_param }
      expect(response).to render_template('confirm_destroy')
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }
    before(:each) { sign_in user }

    it 'destroys the requested user' do
      expect do
        delete :destroy, params: { id: user.to_param }
      end.to change(User, :count).by(-1)
    end

    it 'redirects to the root url' do
      delete :destroy, params: { id: user.to_param }
      expect(response).to redirect_to(root_url)
    end
  end
end

# eof
