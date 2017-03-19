require 'rails_helper'

RSpec.describe 'events/show', type: :view do
  before(:each) do
    @event = assign(:event, create(:event, location: 'Berlin'))
    @app_controller = self
  end

  it 'renders an event' do
    render
    expect(rendered).to match(@event.name)
    expect(rendered).to match(@event.location)
  end

  it 'links to new attendee path when event is open' do
    render
    expect(rendered).to have_selector("a[href='" + new_event_attendee_path(@event) + "']")
  end

  it "doesn't link to new attendee path when event is not open" do
    @event.visible = false
    render
    expect(rendered).not_to have_selector("a[href='" + new_event_attendee_path(@event) + "']")
  end
end
