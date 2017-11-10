require 'rails_helper'

RSpec.describe 'BadgeGroups', type: :request do
  let(:admin) { FactoryBot.create(:user_admin, password: 'foo') }
  let(:badge1) { FactoryBot.create(:badge, badge_type: 'custom') }
  let(:badge2) { FactoryBot.create(:badge, badge_type: 'custom') }
  before(:each) { login_user(admin) }

  it 'sends an empty list of badge groups' do
    get admin_badge_groups_path
    expect(response).to have_http_status(200)
    expect(response).to render_template(:index)
    expect(response.body).to include(I18n.t('admin.badge_groups.no_badge_groups'))
  end

  it 'creates an empty request group' do
    get new_admin_badge_group_path
    expect(response).to render_template(:new)

    post admin_badge_groups_path, params: { badge_group: { name: 'Foo' } }
    expect(response).to have_http_status(302)
    follow_redirect!

    expect(response).to be_success
    expect(response).to render_template(:index)
    expect(response.body).to include('Foo')
    expect(response.body).to include(I18n.t('admin.badge_groups.created'))
  end

  it 'creates a new badge group with a bunch of badges' do
    get new_admin_badge_group_path
    expect(response).to render_template(:new)

    post admin_badge_groups_path, params: { badge_group: { name: 'Foo' }, badges: [badge1.badge_id, badge2.badge_id] }
    expect(response).to have_http_status(302)
    follow_redirect!

    expect(response).to be_success
    expect(response).to render_template(:index)
    expect(response.body).to include('Foo')
    expect(response.body).to include(I18n.t('admin.badge_groups.created'))
  end
end
