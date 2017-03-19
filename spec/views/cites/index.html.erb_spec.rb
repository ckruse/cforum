require 'rails_helper'

RSpec.describe 'cites/index', type: :view do
  before(:each) do
    3.times { create(:cite) }
    assign(:cites, Cite.page(0).all)
  end

  it 'renders a list of cites' do
    @app_controller = self
    render
  end
end
