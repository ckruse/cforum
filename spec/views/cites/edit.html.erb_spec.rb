require 'rails_helper'

RSpec.describe 'cites/edit', type: :view do
  before(:each) do
    @cite = assign(:cite, create(:cite))
  end

  it 'renders the edit cite form' do
    render

    assert_select 'form[action=?][method=?]', cite_path(@cite), 'post' do
    end
  end
end
