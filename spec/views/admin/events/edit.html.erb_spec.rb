require 'rails_helper'

RSpec.describe 'admin/events/edit', type: :view do
  before(:each) do
    @event = assign(:event, create(:event))
  end

  it 'renders the edit event form' do
    render

    assert_select 'form[action=?][method=?]', admin_event_path(@event), 'post' do
      assert_select 'input#event_name[name=?]', 'event[name]'
      assert_select 'input#event_location[name=?]', 'event[location]'
      assert_select 'input#event_maps_link[name=?]', 'event[maps_link]'
      assert_select 'input#event_visible[name=?]', 'event[visible]'
      assert_select 'textarea#event_description[name=?]', 'event[description]'
    end
  end
end
