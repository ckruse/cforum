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
  end

  describe 'POST #flagging' do
    context 'success' do
      it 'flags a message' do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'off-topic' }))
        end.to change(ModerationQueueEntry, :count).by(1)
      end

      it 'flags a message with a duplicate URL' do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'duplicate',
                                                          duplicate_url: message_url(message.thread, message) }))
        end.to change(ModerationQueueEntry, :count).by(1)
      end

      it 'flags a message with custom reason' do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'custom',
                                                          custom_reason: 'foo bar foo bar' }))
        end.to change(ModerationQueueEntry, :count).by(1)
      end

      it 'redirects to message' do
        post(:flagging,
             params: message_params_from_slug(message)
                       .merge(moderation_queue_entry: { reason: 'off-topic' }))
        expect(response).to redirect_to(message_url(message.thread, message))
      end

      it 'increases reported counter on multiple reports' do
        entry = ModerationQueueEntry.create!(message_id: message.message_id,
                                             reason: 'off-topic',
                                             reported: 1)

        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'off-topic' }))
        end.to change(ModerationQueueEntry, :count).by(0)

        entry.reload
        expect(entry.reported).to eq 2
      end
    end

    context 'fail' do
      it "doesn't flag with a missing custom reason" do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'custom',
                                                          custom_reason: '' }))
        end.to change(ModerationQueueEntry, :count).by(0)
      end

      it "doesn't flag with a missing duplicate URL" do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'duplicate',
                                                          duplicate_url: '' }))
        end.to change(ModerationQueueEntry, :count).by(0)
      end

      it "doesn't accept bullshit as reason" do
        expect do
          post(:flagging,
               params: message_params_from_slug(message)
                         .merge(moderation_queue_entry: { reason: 'some bullshit' }))
        end.to change(ModerationQueueEntry, :count).by(0)
      end
    end
  end
end

# eof
