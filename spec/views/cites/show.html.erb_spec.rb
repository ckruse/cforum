require 'rails_helper'

RSpec.describe "cites/show", type: :view do
  def conf(name)
    ConfigManager::DEFAULTS[name]
  end

  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  helper_method :uconf, :conf

  before(:each) do
    @cite = assign(:cite, create(:cite))
  end

  it "renders attributes in <p>" do
    @app_controller = self
    render
  end
end
