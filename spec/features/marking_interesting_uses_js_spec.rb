require 'rails_helper'

describe 'marking as interesting uses JS' do
  let(:message) { create(:message) }
  let(:user) { create(:user) }

  before(:each) { login_as(user, scope: :user) }

  include CForum::Tools

  it "doesn't reload when clicking the mark interesting icon", js: true do
    visit forum_path(message.forum)

    page.find('#m' + message.message_id.to_s + ' .mark-interesting').click
    wait_for_ajax
    expect(page.body).to have_css('#m' + message.message_id.to_s + ' .mark-boring')
    expect(InterestingMessage.where(user_id: user.user_id,
                                    message_id: message.message_id).first).not_to be_nil

    page.find('#m' + message.message_id.to_s + ' .mark-boring').click
    wait_for_ajax
    expect(page.body).to have_css('#m' + message.message_id.to_s + ' .mark-interesting')
    expect(InterestingMessage.where(user_id: user.user_id,
                                    message_id: message.message_id).first).to be_nil
  end
end

# eof
