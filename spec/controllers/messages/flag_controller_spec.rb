# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe Messages::FlagController do
  let(:message) { create(:message) }
  let(:user) { create(:user_admin) }
  before(:each) { sign_in user }

  describe 'GET #flag' do
    it 'assigns the message as @message' do
      get :flag, params: message_params_from_slug(message)
      expect(assigns(:message)).to eq(message)
    end

    it 'redirects to message when message is already flagged' do
      message.flags_will_change!
      message.flags['flagged'] = 'off-topic'
      message.save!

      get :flag, params: message_params_from_slug(message)

      expect(response).to redirect_to(message_url(message.thread, message))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST #flagging' do
    context 'success' do
      it 'flags a message' do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'off-topic')
        message.reload
        expect(message.flags['flagged']).to eq 'off-topic'
      end

      it 'flags a message with a duplicate URL' do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'duplicate',
                                                                        duplicate_slug: message_url(message.thread, message))
        message.reload
        expect(message.flags['flagged']).to eq 'duplicate'
        expect(message.flags['flagged_dup_url']).to eq message_url(message.thread, message)
      end
      it 'flags a message with custom reason' do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'custom',
                                                                        custom_reason: 'foo bar foo bar')
        message.reload
        expect(message.flags['flagged']).to eq 'custom'
        expect(message.flags['custom_reason']).to eq 'foo bar foo bar'
      end

      it 'redirects to message' do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'off-topic')
        expect(response).to redirect_to(message_url(message.thread, message))
      end
    end

    context 'fail' do
      it "doesn't flag an already flagged message" do
        message.flags_will_change!
        message.flags['flagged'] = 'off-topic'
        message.save

        post :flagging, params: message_params_from_slug(message).merge(reason: 'not-constructive')

        expect(response).to redirect_to(message_url(message.thread, message))
        expect(flash[:notice]).to be_present
      end

      it "doesn't flag with a missing custom reason" do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'custom')
        message.reload
        expect(message.flags['flagged']).to be nil
        expect(message.flags['custom_reason']).to be nil
        expect(flash[:error]).to be_present
      end

      it "doesn't flag with a missing duplicate URL" do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'duplicate')
        message.reload
        expect(message.flags['flagged']).to be nil
        expect(message.flags['flagged_dup_url']).to be nil
        expect(flash[:error]).to be_present
      end

      it "doesn't accept bullshit as reason" do
        post :flagging, params: message_params_from_slug(message).merge(reason: 'foobar')
        message.reload
        expect(message.flags['flagged']).to be nil
        expect(flash[:error]).to be_present
      end
    end
  end

  describe 'GET #unflag' do
    before(:each) do
      message.flags_will_change!
      message.flags['flagged'] = 'custom'
      message.flags['custom_reason'] = 'custom'
      message.flags['flagged_dup_url'] = 'custom'
      message.save!
    end

    it 'removes flagged' do
      post :unflag, params: message_params_from_slug(message)
      message.reload
      expect(message.flags['flagged']).to be nil
    end

    it 'removes custom reason' do
      post :unflag, params: message_params_from_slug(message)
      message.reload
      expect(message.flags['custom_reason']).to be nil
    end

    it 'removen dup url' do
      post :unflag, params: message_params_from_slug(message)
      message.reload
      expect(message.flags['flagged_dup_url']).to be nil
    end

    it 'redirects to message' do
      post :unflag, params: message_params_from_slug(message)
      message.reload
      expect(response).to redirect_to(message_url(message.thread, message))
    end
  end
end

# eof
