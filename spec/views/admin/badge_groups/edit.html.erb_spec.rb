require 'rails_helper'

RSpec.describe 'admin/badge_groups/edit', type: :view do
  before(:each) do
    @badge_group = assign(:badge_group, FactoryBot.create(:badge_group))
    @badges = assign(:badges, Badge.order(:order).all)
  end

  it 'renders the edit badge_group form' do
    render

    assert_select 'form[action=?][method=?]', admin_badge_group_path(@badge_group), 'post' do
      assert_select 'input#badge_group_name[name=?]', 'badge_group[name]'
    end
  end
end
