require 'rails_helper'

RSpec.describe Messages::AcceptController, type: :controller do
  let(:user) { create(:user) }
  let(:user1) { create(:user) }
  let(:message) { create(:message, owner: user1) }
  let(:message1) { create(:message, owner: user) }

  before(:each) do
    message1.parent_id = message.parent_id
    message1.thread_id = message.thread_id
    message1.save
  end

  it 'should accept when user is OP' do
    sign_in user1

    post :accept, params: message_params_from_slug(message1)

    user.reload
    message1.reload

    expect(flash[:error]).to be_nil
    expect(message1.flags['accepted']).to eq 'yes'
    expect(user.score).not_to eq 0
  end

  it "should not accept when user isn't OP" do
    sign_in user

    post :accept, params: message_params_from_slug(message1)

    user.reload
    message1.reload

    expect(flash[:error]).not_to be_nil
    expect(message1.flags['accepted']).to be_nil
    expect(user.score).to eq 0
  end

  it 'should accept more than one answer' do
    sign_in user1
    msg2 = create(:message, owner: user)
    msg2.parent_id = message1.message_id
    msg2.thread_id = message1.thread_id
    msg2.save

    post :accept, params: message_params_from_slug(message1)
    post :accept, params: message_params_from_slug(msg2)

    user.reload
    message1.reload
    msg2.reload

    expect(flash[:error]).to be_nil
    expect(message1.flags['accepted']).to eq 'yes'
    expect(msg2.flags['accepted']).to eq 'yes'
    expect(user.score).not_to eq 0
  end

  it 'should unaccept' do
    sign_in user1

    message1.flags['accepted'] = 'yes'
    message1.save

    post :accept, params: message_params_from_slug(message1)

    user.reload
    message1.reload

    expect(flash[:error]).to be_nil
    expect(message1.flags['accepted']).to be_nil
  end

  it 'should remove score when unaccepting' do
    sign_in user1

    message1.flags['accepted'] = 'yes'
    message1.save

    Score.create!(user_id: message1.user_id,
                  message_id: message1.message_id,
                  value: 15)

    post :accept, params: message_params_from_slug(message1)

    user.reload
    message1.reload

    expect(flash[:error]).to be_nil
    expect(message1.flags['accepted']).to be_nil
    expect(user.score).to eq 0
  end
end

# eof
