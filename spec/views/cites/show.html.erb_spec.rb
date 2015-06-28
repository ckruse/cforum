require 'rails_helper'

RSpec.describe "cites/show", type: :view do
  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  helper_method :uconf

  before(:each) do
    @cite = assign(:cite, create(:cf_cite))
  end

  it "renders attributes in <p>" do
    render
  end
end
