require 'rails_helper'

RSpec.describe "admin/badge_groups/index", type: :view do
  def conf(name)
    ConfigManager::DEFAULTS[name]
  end

  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  helper_method :uconf, :conf

  let(:badge_groups) do
    [ FactoryGirl.create(:badge_group),
      FactoryGirl.create(:badge_group) ]
  end

  before(:each) do
    assign(:badge_groups, badge_groups)
  end

  it "renders a list of badge_groups" do
    render
    assert_select "tr>td", text: badge_groups.first.name
  end
end