require 'rails_helper'

RSpec.describe "events/show", type: :view do
  before(:each) do
    @event = assign(:event, create(:event, location: 'Berlin'))
    @app_controller = self
  end

  it "renders an event" do
    render
    expect(rendered).to match(@event.name)
    expect(rendered).to match(@event.location)
  end
end
