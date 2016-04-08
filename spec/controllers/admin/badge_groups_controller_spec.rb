# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe Admin::BadgeGroupsController, type: :controller do

  let(:admin) { FactoryGirl.create(:user_admin) }

  # This should return the minimal set of attributes required to create a valid
  # BadgeGroup. As you add validations to BadgeGroup, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    #skip("Add a hash of attributes valid for your model")
    {name: "Foo"}
  }

  let(:invalid_attributes) {
    {name: ''}
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BadgeGroupsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before(:each) { sign_in admin }

  describe "GET #index" do
    it "assigns all badge_groups as @badge_groups" do
      badge_group = BadgeGroup.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:badge_groups)).to eq([badge_group])
    end
  end

  describe "GET #new" do
    it "assigns a new badge_group as @badge_group" do
      get :new, {}, valid_session
      expect(assigns(:badge_group)).to be_a_new(BadgeGroup)
    end
  end

  describe "GET #edit" do
    it "assigns the requested badge_group as @badge_group" do
      badge_group = BadgeGroup.create! valid_attributes
      get :edit, {id: badge_group.to_param}, valid_session
      expect(assigns(:badge_group)).to eq(badge_group)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new BadgeGroup" do
        expect {
          post :create, {badge_group: valid_attributes}, valid_session
        }.to change(BadgeGroup, :count).by(1)
      end

      it "assigns a newly created badge_group as @badge_group" do
        post :create, {badge_group: valid_attributes}, valid_session
        expect(assigns(:badge_group)).to be_a(BadgeGroup)
        expect(assigns(:badge_group)).to be_persisted
      end

      it "redirects to the badge_group index" do
        post :create, {badge_group: valid_attributes}, valid_session
        expect(response).to redirect_to(admin_badge_groups_url)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved badge_group as @badge_group" do
        post :create, {badge_group: invalid_attributes}, valid_session
        expect(assigns(:badge_group)).to be_a_new(BadgeGroup)
      end

      it "re-renders the 'new' template" do
        post :create, {badge_group: invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {name: 'Foo 1'}
      }

      it "updates the requested badge_group" do
        badge_group = BadgeGroup.create! valid_attributes
        put :update, {id: badge_group.to_param, badge_group: new_attributes}, valid_session
        badge_group.reload
        expect(badge_group.name).to eq 'Foo 1'
      end

      it "assigns the requested badge_group as @badge_group" do
        badge_group = BadgeGroup.create! valid_attributes
        put :update, {id: badge_group.to_param, badge_group: valid_attributes}, valid_session
        expect(assigns(:badge_group)).to eq(badge_group)
      end

      it "redirects to the badge_group" do
        badge_group = BadgeGroup.create! valid_attributes
        put :update, {id: badge_group.to_param, badge_group: valid_attributes}, valid_session
        expect(response).to redirect_to(admin_badge_groups_url)
      end
    end

    context "with invalid params" do
      it "assigns the badge_group as @badge_group" do
        badge_group = BadgeGroup.create! valid_attributes
        put :update, {id: badge_group.to_param, badge_group: invalid_attributes}, valid_session
        expect(assigns(:badge_group)).to eq(badge_group)
      end

      it "re-renders the 'edit' template" do
        badge_group = BadgeGroup.create! valid_attributes
        put :update, {id: badge_group.to_param, badge_group: invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested badge_group" do
      badge_group = BadgeGroup.create! valid_attributes
      expect {
        delete :destroy, {id: badge_group.to_param}, valid_session
      }.to change(BadgeGroup, :count).by(-1)
    end

    it "redirects to the badge_groups list" do
      badge_group = BadgeGroup.create! valid_attributes
      delete :destroy, {id: badge_group.to_param}, valid_session
      expect(response).to redirect_to(admin_badge_groups_url)
    end
  end

end

# eof
