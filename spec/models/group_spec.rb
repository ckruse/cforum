require 'rails_helper'

RSpec.describe Group, type: :model do
  it 'is valid with a name' do
    expect(Group.new(name: 'Rebellion')).to be_valid
  end

  it 'is invalid wo a name' do
    expect(Group.new).to be_invalid
  end

  it 'is invalid with a too long name' do
    expect(Group.new(name: 'Rebellion' * 255)).to be_invalid
  end

  it 'is invalid with a duplicate name' do
    Group.create!(name: 'Rebellion')
    expect(Group.new(name: 'Rebellion')).to be_invalid
  end
end

# eof
