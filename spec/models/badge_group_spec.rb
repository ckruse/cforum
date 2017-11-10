require 'rails_helper'

RSpec.describe BadgeGroup, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:badge_group)).to be_valid
  end

  it 'is invalid without a name' do
    expect(FactoryBot.build(:badge_group, name: nil)).not_to be_valid
  end

  it 'does not allow duplicate names' do
    FactoryBot.create(:badge_group, name: 'Group 1')
    expect(FactoryBot.build(:badge_group, name: 'Group 1')).not_to be_valid
    expect(FactoryBot.build(:badge_group, name: 'group 1')).not_to be_valid
  end
end
