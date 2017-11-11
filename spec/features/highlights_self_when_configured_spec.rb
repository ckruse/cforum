require 'rails_helper'

RSpec.describe 'highlights self when configured' do
  let(:user) { create(:user, username: 'foo') }
  let(:message) do
    create(:message,
           content: 'blah blub bar @foo',
           author: 'foo',
           owner: user,
           flags: { mentions: [['foo', user.user_id, false]] })
  end
  before(:each) do
    login_as(user)
    Setting.create!(user_id: message.user_id, options: { 'highlight_self' => 'yes' })
  end

  include ApplicationHelper

  it 'highlights self in message' do
    visit(message_path(message.thread, message))
    expect(page.find('.root')).to have_css('.highlighted-self.' + user_to_class_name(message.author))
    expect(page.find('.thread-message:not(.preview) .posting-content'))
      .to have_css('.highlighted-self.' + user_to_class_name(message.author))
  end
  it 'highlights self in thread tree' do
    visit(forum_path(message.forum))
    expect(page.find('.root')).to have_css('.highlighted-self.' + user_to_class_name(message.author))
  end
end
