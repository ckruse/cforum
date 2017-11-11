require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { FactoryBot.create(:user_admin) }

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns all users as @users' do
      get :index
      expect(assigns(:users)).to eq([admin])
    end

    it 'searches user with s param' do
      users = [create(:user), create(:user), create(:user)]
      get :index, params: { s: users.first.username }
      expect(assigns(:users)).to eq([users.first])
    end
  end

  describe 'GET #new' do
    it 'assigns a new user as @user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested user as @user' do
      user = create(:user)
      get :edit, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new user' do
        expect do
          post :create, params: { user: attributes_for(:user) }
        end.to change(User, :count).by(1)
      end

      it 'assigns a newly created user as @user' do
        post :create, params: { user: attributes_for(:user) }
        expect(assigns(:user)).to be_a(User)
        expect(assigns(:user)).to be_persisted
      end

      it 'redirects to the user' do
        post :create, params: { user: attributes_for(:user) }
        expect(response).to redirect_to(edit_admin_user_url(assigns(:user)))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { username: '' }
      end

      it 'assigns a newly created but unsaved user as @user' do
        post :create, params: { user: invalid_attributes }
        expect(assigns(:user)).to be_a_new(User)
      end

      it "re-renders the 'new' template" do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { username: 'Foo 1' }
      end

      it 'updates the requested user' do
        user = create(:user)
        put :update, params: { id: user.to_param, user: new_attributes }
        user.reload
        expect(user.username).to eq 'Foo 1'
      end

      it 'assigns the requested user as @user' do
        user = create(:user)
        put :update, params: { id: user.to_param, user: new_attributes }
        expect(assigns(:user)).to eq(user)
      end

      it 'redirects to the user' do
        user = create(:user)
        put :update, params: { id: user.to_param, user: new_attributes }
        expect(response).to redirect_to(edit_admin_user_url(user))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { username: '' }
      end

      it 'assigns the user as @user' do
        user = create(:user)
        put :update, params: { id: user.to_param, user: invalid_attributes }
        expect(assigns(:user)).to eq(user)
      end

      it "re-renders the 'edit' template" do
        user = create(:user)
        put :update, params: { id: user.to_param, user: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested user' do
      user = create(:user)
      expect do
        delete :destroy, params: { id: user.to_param }
      end.to change(User, :count).by(-1)
    end

    it 'redirects to the users list' do
      user = create(:user)
      delete :destroy, params: { id: user.to_param }
      expect(response).to redirect_to(admin_users_url)
    end
  end
end

# eof
