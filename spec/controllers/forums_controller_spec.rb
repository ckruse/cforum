require 'rails_helper'

RSpec.describe ForumsController, type: :controller do
  let(:forum) { create(:forum) }

  describe 'Stats' do
    it 'shows stats for a specific forum' do
      get :stats, params: { curr_forum: forum.slug }
      expect(response.status).to eq(200)
      expect(response).to render_template('stats')
    end

    it 'shows stats for all forums' do
      get :stats, params: { curr_forum: 'all' }
      expect(response.status).to eq(200)
      expect(response).to render_template('stats')
    end
  end

  describe 'Locked' do
    let(:user) { create(:user) }
    let(:admin) { create(:user_admin) }
    let(:moderator) { create(:user_moderator) }

    before(:each) do
      Setting.create!(options: { 'locked' => 'yes' })
    end

    it 'renders locked for anonymouse users' do
      get :index
      expect(response.status).to eq(403)
    end

    it 'renders locked for normal users' do
      sign_in user
      get :index
      expect(response.status).to eq(403)
    end

    it 'renders locked for moderator users' do
      sign_in moderator
      get :index
      expect(response.status).to eq(403)
    end

    it 'does not lock for admins' do
      sign_in admin
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe 'view_all' do
    let(:user) { create(:user) }
    let(:admin) { create(:user_admin) }
    let(:moderator) { create(:user_moderator) }

    it 'sets view_all for admins' do
      sign_in admin
      get :index, params: { view_all: 'yes' }
      expect(assigns[:view_all]).to eq(true)
    end

    it 'sets view_all for global moderators' do
      sign_in moderator
      get :index, params: { view_all: 'yes' }
      expect(assigns[:view_all]).to eq(true)
    end

    it "doesn't set view_all for anonymouse users" do
      get :index, params: { view_all: 'yes' }
      expect(assigns[:view_all]).to be_nil
    end

    it "doesn't set view_all for normal users" do
      sign_in user
      get :index, params: { view_all: 'yes' }
      expect(assigns[:view_all]).to be_nil
    end

    it "doesn't set view_all for forum moderators" do
      perm = create(:forum_group_moderate_permission)
      perm.group.users << user
      sign_in user

      get :index, params: { view_all: 'yes' }
      expect(assigns[:view_all]).to be_nil
    end

    it 'sets view_all for forum moderators on forum' do
      perm = create(:forum_group_moderate_permission)
      perm.group.users << user
      sign_in user

      get :stats, params: { view_all: 'yes', curr_forum: perm.forum.slug }
      expect(assigns[:view_all]).to be true
    end
  end
end

# eof
