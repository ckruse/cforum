require 'rails_helper'

RSpec.describe 'admin/badge_groups/new', type: :view do
  before(:each) do
    assign(:badge_group, FactoryBot.build(:badge_group, name: 'Foo'))
    @badges = assign(:badges, Badge.order(:order).all)
  end

  it 'renders new badge_group form' do
    render

    assert_select 'form[action=?][method=?]', admin_badge_groups_path, 'post' do
      assert_select 'input#badge_group_name[name=?]', 'badge_group[name]'
    end
  end
end
