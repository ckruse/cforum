require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller do
  let(:admin) { FactoryBot.create(:user_admin) }

  before(:each) do
    sign_in admin
  end

  describe 'GET #edit' do
    it 'assigns the settings @settings' do
      settings = create(:setting)
      get :edit
      expect(assigns(:settings)).to eq(settings)
    end

    it 'assigns a new setting to @settings' do
      get :edit
      expect(assigns(:settings)).to be_a_new(Setting)
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { 'a' => '_DEFAULT_', 'b' => 'c' }
      end

      it 'creates a new setting' do
        expect do
          put :update, params: { settings: new_attributes }
        end.to change(Setting, :count).by(1)
      end

      it 'updates the requested settings' do
        setting = create(:setting)
        put :update, params: { settings: new_attributes }
        setting.reload
        expect(setting.options).to eq('b' => 'c')
      end

      it 'assigns the requested settings as @settings' do
        settings = create(:setting)
        put :update, params: { settings: new_attributes }
        expect(assigns(:settings)).to eq(settings)
      end

      it 'redirects to edit' do
        put :update, params: { settings: new_attributes }
        expect(response).to redirect_to(admin_settings_url)
      end
    end
  end
end

# eof
