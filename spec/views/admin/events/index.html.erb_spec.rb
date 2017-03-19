require 'rails_helper'

RSpec.describe 'admin/events/index', type: :view do
  let(:events) { [create(:event), create(:event)] }
  before(:each) do
    events # ensure that events get created
    assign(:events, Event.all.page(0))
  end

  it 'renders a list of events' do
    render
    assert_select 'tr>td', text: events.first.name, count: 1
    assert_select 'tr>td', text: events.second.name, count: 1
  end
end
