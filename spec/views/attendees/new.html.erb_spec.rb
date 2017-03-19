require 'rails_helper'

RSpec.describe 'attendees/new', type: :view do
  let(:event) { create(:event) }
  let(:attendee) { build(:attendee, event: event) }

  before(:each) do
    assign(:attendee, attendee)
    assign(:event, event)
  end

  it 'renders new attendee form' do
    render

    assert_select 'form[action=?][method=?]', event_attendees_path(event), 'post' do
      assert_select 'input#attendee_name[name=?]', 'attendee[name]'
      assert_select 'textarea#attendee_comment[name=?]', 'attendee[comment]'
      assert_select 'input#attendee_starts_at[name=?]', 'attendee[starts_at]'
      assert_select 'input#attendee_seats[name=?]', 'attendee[seats]'
    end
  end
end
