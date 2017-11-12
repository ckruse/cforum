require 'rails_helper'

RSpec.describe Admin::GroupsController, type: :controller do
  let(:admin) { create(:user_admin) }

  before(:each) { sign_in admin }

  describe 'GET #index' do
    it 'assigns all groups as @groups' do
      group = create(:group)
      get :index
      expect(assigns(:groups)).to eq([group])
    end
  end

  describe 'GET #new' do
    it 'assigns a new group as @group' do
      get :new
      expect(assigns(:group)).to be_a_new(Group)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested group as @group' do
      group = create(:group)
      get :edit, params: { id: group.to_param }
      expect(assigns(:group)).to eq(group)
    end

    it 'assigns all forums as @forums' do
      group = create(:group)
      forum = create(:forum)
      get :edit, params: { id: group.to_param }
      expect(assigns(:forums)).to eq([forum])
    end

    it 'assigns group users as @users' do
      group = create(:group)
      get :edit, params: { id: group.to_param }
      expect(assigns(:users)).to eq(group.users)
    end
    it 'assigns permissions as @forums_groups_permissions' do
      group = create(:group)
      get :edit, params: { id: group.to_param }
      expect(assigns(:forums_groups_permissions)).to eq(group.forums_groups_permissions)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new group' do
        expect do
          post :create, params: { group: attributes_for(:group) }
        end.to change(Group, :count).by(1)
      end

      it 'assigns a newly created group as @group' do
        post :create, params: { group: attributes_for(:group) }
        expect(assigns(:group)).to be_a(Group)
        expect(assigns(:group)).to be_persisted
      end

      it 'redirects to the new group' do
        post :create, params: { group: attributes_for(:group) }
        expect(response).to redirect_to(edit_admin_group_url(assigns(:group)))
      end

      it 'creates the users as an association' do
        users = create_list(:user, 3)
        expect do
          post :create, params: { group: attributes_for(:group), users: users.map(&:user_id) }
        end.to change(GroupUser, :count).by(3)
      end

      it 'creates permissions as an association' do
        forums = create_list(:forum, 3)
        expect do
          post(:create, params: { group: attributes_for(:group),
                                  forums: forums.map(&:forum_id),
                                  permissions: %w[read read read] })
        end.to change(ForumGroupPermission, :count).by(3)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns a newly created but unsaved group as @group' do
        post :create, params: { group: invalid_attributes }
        expect(assigns(:group)).to be_a_new(Group)
      end

      it "re-renders the 'new' template" do
        post :create, params: { group: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:group) { create(:group) }
      let(:new_attributes) do
        { name: 'Foo bar' }
      end

      it 'updates the requested group' do
        put :update, params: { id: group.to_param, group: new_attributes }
        group.reload
        expect(group.name).to eql('Foo bar')
      end

      it 'assigns the requested group as @group' do
        put :update, params: { id: group.to_param, group: new_attributes }
        group.reload
        expect(assigns(:group)).to eq(group)
      end

      it 'redirects to the updated group' do
        put :update, params: { id: group.to_param, group: new_attributes }
        expect(response).to redirect_to(edit_admin_group_url(group))
      end

      it 'creates the users as an association' do
        users = create_list(:user, 3)
        expect do
          post :update, params: { id: group.to_param, group: new_attributes, users: users.map(&:user_id) }
        end.to change(GroupUser, :count).by(3)
      end

      it 'creates permissions as an association' do
        forums = create_list(:forum, 3)
        group.forums_groups_permissions.clear
        expect do
          post(:update, params: { id: group.to_param,
                                  group: new_attributes,
                                  forums: forums.map(&:forum_id),
                                  permissions: %w[read read read] })
        end.to change(ForumGroupPermission, :count).by(3)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns the group as @group' do
        group = create(:group)
        put :update, params: { id: group.to_param, group: invalid_attributes }
        expect(assigns(:group)).to eq(group)
      end

      it "re-renders the 'edit' template" do
        group = create(:group)
        put :update, params: { id: group.to_param, group: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested group' do
      group = create(:group)
      expect do
        delete :destroy, params: { id: group.to_param }
      end.to change(Group, :count).by(-1)
    end

    it 'redirects to the groups list' do
      group = create(:group)
      delete :destroy, params: { id: group.to_param }
      expect(response).to redirect_to(admin_groups_url)
    end
  end
end
