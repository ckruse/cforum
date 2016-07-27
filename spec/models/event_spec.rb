require 'rails_helper'

RSpec.describe Event, type: :model do
  it "is valid with name, description, start_date and end_date" do
    expect(Event.new(name: 'Foo', description: 'bar', start_date: Time.zone.now, end_date: Time.zone.now)).to be_valid
  end

  it "is invalid w/o name" do
    expect(Event.new(description: 'bar', start_date: Time.zone.now, end_date: Time.zone.now)).to be_invalid
  end
  it "is invalid w/o description" do
    expect(Event.new(name: 'Foo', start_date: Time.zone.now, end_date: Time.zone.now)).to be_invalid
  end
  it "is invalid w/o start_date" do
    expect(Event.new(name: 'Foo', description: 'bar', end_date: Time.zone.now)).to be_invalid
  end
  it "is invalid w/o end_date" do
    expect(Event.new(name: 'Foo', description: 'bar', start_date: Time.zone.now)).to be_invalid
  end
end
