require 'rails_helper'

RSpec.describe Event, type: :model do
  it 'is valid with name, description, start_date and end_date' do
    expect(Event.new(name: 'Foo', description: 'bar', start_date: Time.zone.now, end_date: Time.zone.now)).to be_valid
  end

  it 'is invalid w/o name' do
    expect(Event.new(description: 'bar', start_date: Time.zone.now, end_date: Time.zone.now)).to be_invalid
  end
  it 'is invalid w/o description' do
    expect(Event.new(name: 'Foo', start_date: Time.zone.now, end_date: Time.zone.now)).to be_invalid
  end
  it 'is invalid w/o start_date' do
    expect(Event.new(name: 'Foo', description: 'bar', end_date: Time.zone.now)).to be_invalid
  end
  it 'is invalid w/o end_date' do
    expect(Event.new(name: 'Foo', description: 'bar', start_date: Time.zone.now)).to be_invalid
  end

  context 'attendee?' do
    let(:user) { create(:user) }
    let(:attendee) { create(:attendee, user: user) }

    it 'returns the attendee for attendee?' do
      expect(attendee.event.attendee?(user)).to eql attendee
    end
    it 'returns nil when user is not an attendee' do
      expect(attendee.event.attendee?(create(:user))).to be_nil
    end
  end

  context 'open?' do
    it 'returns true when the event is open and visible' do
      expect(build(:event).open?).to be true
    end
    it 'returns false when the event is not open' do
      expect(build(:event, start_date: Date.today - 3, end_date: Date.today - 4).open?).to be false
    end
    it 'returns false when the event is invisible' do
      expect(build(:event, visible: false).open?).to be false
    end
    it 'returns true when the event has started but not ended' do
      expect(build(:event, start_date: Date.today - 3, end_date: Date.today + 3).open?).to be true
    end
  end
end
