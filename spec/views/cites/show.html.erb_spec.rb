require 'rails_helper'

RSpec.describe 'cites/show', type: :view do
  before(:each) do
    @cite = assign(:cite, create(:cite))
  end

  it 'renders attributes in <p>' do
    @app_controller = self
    render
  end
end
