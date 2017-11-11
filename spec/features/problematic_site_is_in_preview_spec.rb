require 'rails_helper'

RSpec.describe 'problematic site is in preview', js: true do
  let(:message) { create(:message) }

  include CForum::Tools

  describe 'for answer' do
    it 'has no problematic site when value is empty' do
      visit new_message_path(message.thread, message)
      page.find('#message_problematic_site').set('abc')
      expect(page.find('.thread-message.preview')).to have_css('.problematic-site')
    end

    it 'has problematic site when value is not empty' do
      visit new_message_path(message.thread, message)
      page.find('#message_problematic_site').set('abc')
      expect(page.find('.thread-message.preview')).to have_css('.problematic-site')
      page.find('#message_problematic_site').set('')
      expect(page.find('.thread-message.preview')).not_to have_css('.problematic-site')
    end
  end

  describe 'for new thread' do
    it 'has no problematic site when value is empty' do
      visit new_cf_thread_path(message.forum)

      page.find('#cf_thread_message_problematic_site').set('abc')
      expect(page.find('.thread-message.preview')).to have_css('.problematic-site')
    end

    it 'has problematic site when value is not empty' do
      visit new_cf_thread_path(message.forum)

      page.find('#cf_thread_message_problematic_site').set('abc')
      expect(page.find('.thread-message.preview')).to have_css('.problematic-site')
      page.find('#cf_thread_message_problematic_site').set('')
      expect(page.find('.thread-message.preview')).not_to have_css('.problematic-site')
    end
  end
end

# eof
