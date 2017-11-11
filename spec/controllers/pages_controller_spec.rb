require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #help' do
    it 'assigns moderators and admins as @moderators' do
      users = [create(:user_admin), create(:user_moderator)]
      get :help
      expect(assigns(:moderators)).to eq(users)
    end

    it 'assigns badge groups as @badge_groups' do
      bg = create(:badge_group)
      get :help
      expect(assigns(:badge_groups)).to eq([bg])
    end
  end
end

# eof
