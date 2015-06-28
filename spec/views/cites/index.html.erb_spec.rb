require 'rails_helper'

RSpec.describe "cites/index", type: :view do
  before(:each) do
    assign(:cites, [
      create(:cf_cite),
      create(:cf_cite)
    ])
  end

  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  helper_method :uconf

  it "renders a list of cites" do
    render
  end
end
