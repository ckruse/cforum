require 'rails_helper'

RSpec.describe CfThreads::NoArchiveController, type: :controller do
  let(:message) { create(:message) }
  let(:user) { create(:user_admin) }
  before(:each) { sign_in user }

  describe 'POST #no_archive' do
    it "marks a thread as „don't archive”" do
      post :no_archive, params: thread_params_from_slug(message.thread)
      message.thread.reload
      expect(message.thread.flags['no-archive']).to eq 'yes'
    end
  end

  describe 'POST #archive' do
    it 'marks a thread as „do archive”' do
      message.thread.flags_will_change!
      message.thread.flags['no-archive'] = 'yes'
      message.thread.save

      post :archive, params: thread_params_from_slug(message.thread)
      message.thread.reload
      expect(message.thread.flags['no-archive']).to be nil
    end
  end
end

# eof
