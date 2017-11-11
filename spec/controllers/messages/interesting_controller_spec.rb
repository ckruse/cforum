require 'rails_helper'

RSpec.describe Messages::InterestingController, type: :controller do
  let(:message) { create(:message) }
  let(:user) { create(:user) }

  before(:each) do
    sign_in user
  end

  it 'should mark interesting' do
    post :mark_interesting, params: message_params_from_slug(message)

    expect(flash[:error]).to be_nil
    expect(InterestingMessage.where(user_id: user.user_id,
                                    message_id: message.message_id).first).not_to be_nil
  end

  it 'should mark boring' do
    InterestingMessage.create!(user_id: user.user_id,
                               message_id: message.message_id)

    post :mark_boring, params: message_params_from_slug(message)

    expect(flash[:error]).to be_nil
    expect(InterestingMessage.where(user_id: user.user_id,
                                    message_id: message.message_id).first).to be_nil
  end

  it 'should list interesting messages' do
    InterestingMessage.create!(user_id: user.user_id,
                               message_id: message.message_id)

    get :list_interesting_messages

    expect(flash[:error]).to be_nil
    expect(assigns(:messages)).to eq [message]
  end
end

# eof
