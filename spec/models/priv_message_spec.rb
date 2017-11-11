require 'rails_helper'

RSpec.describe PrivMessage, type: :model do
  it 'is valid with subject, body, sender_id, recipient_id, owner_id, sender_name and recipient_name' do
    expect(PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                           body: 'The blue prints of the death star revealed a security problem',
                           sender_id: 1,
                           recipient_id: 2,
                           owner_id: 1,
                           sender_name: 'Abc',
                           recipient_name: 'Def')).to be_valid
  end

  it 'is invalid wo subject' do
    expect(PrivMessage.new(body: 'The blue prints of the death star revealed a security problem',
                           sender_id: 1,
                           recipient_id: 2,
                           owner_id: 1)).to be_invalid
  end

  it 'is invalid wo body' do
    expect(PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                           sender_id: 1,
                           recipient_id: 2,
                           owner_id: 1)).to be_invalid
  end

  it 'is invalid wo sender_id' do
    expect(PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                           body: 'The blue prints of the death star revealed a security problem',
                           recipient_id: 2,
                           owner_id: 1)).to be_invalid
  end

  it 'is invalid wo recipient_id' do
    expect(PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                           body: 'The blue prints of the death star revealed a security problem',
                           sender_id: 1,
                           owner_id: 1)).to be_invalid
  end

  it 'is invalid wo owner_id' do
    expect(PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                           body: 'The blue prints of the death star revealed a security problem',
                           sender_id: 1,
                           recipient_id: 2)).to be_invalid
  end

  it 'returns the other id for partner' do
    pm = PrivMessage.new(subject: 'Regarding: blue prints of the death star',
                         body: 'The blue prints of the death star revealed a security problem',
                         sender_id: 1,
                         recipient_id: 2,
                         owner_id: 1)
    expect(pm.partner_id(build(:user, user_id: 1))).to eq 2
    expect(pm.partner_id(build(:user, user_id: 2))).to eq 1
  end
end

# eof
