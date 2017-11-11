require 'rails_helper'

RSpec.describe Messages::NoAnswerController, type: :controller do
  let(:message) { create(:message) }
  let(:user) { create(:user_admin) }
  before(:each) { sign_in user }

  describe 'POST #forbid_answer' do
    it 'forbids the answer to a message' do
      post :forbid_answer, params: message_params_from_slug(message)
      message.reload
      expect(message.open?).to be false
    end
  end

  describe 'POST #allow_answer' do
    it 'allows the answer to a message' do
      message.flags_will_change!
      message.flags['no-answer-admin'] = 'yes'
      message.save!

      post :allow_answer, params: message_params_from_slug(message)
      message.reload
      expect(message.open?).to be true
    end
  end
end

# eof
