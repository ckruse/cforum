# -*- coding: utf-8 -*-

require "rails_helper"

describe Messages::InterestingController do
  let(:message) { create(:message) }
  let(:user) { create(:user) }

  it "should mark interesting" do
    sign_in user

    post :mark_interesting, message_params_from_slug(message)

    expect(flash[:error]).to be_nil
    expect(InterestingMessage.where(user_id: user.user_id,
                                      message_id: message.message_id).first).not_to be_nil
  end

  it "should mark boring" do
    sign_in user

    InterestingMessage.create!(user_id: user.user_id,
                                 message_id: message.message_id)

    post :mark_boring, message_params_from_slug(message)

    expect(flash[:error]).to be_nil
    expect(InterestingMessage.where(user_id: user.user_id,
                                      message_id: message.message_id).first).to be_nil
  end

  it "should list interesting messages" do
    sign_in user

    InterestingMessage.create!(user_id: user.user_id,
                                 message_id: message.message_id)

    get :list_interesting_messages

    expect(flash[:error]).to be_nil
    expect(assigns(:messages)).to eq [message]
  end
end

# eof