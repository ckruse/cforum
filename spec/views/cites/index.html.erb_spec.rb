require 'rails_helper'

RSpec.describe "cites/index", type: :view do
  def conf(name)
    ConfigManager::DEFAULTS[name]
  end

  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  helper_method :uconf, :conf

  before(:each) do
    3.times { create(:cf_cite) }
    assign(:cites, CfCite.page(0).all)
  end

  it "renders a list of cites" do
    @app_controller = self
    render
  end
end
