require 'rails_helper'

RSpec.describe ThreadMovedMailer, type: :mailer do
  include CForum::Tools

  describe 'thread moved' do
    let(:user) { create(:user) }
    let(:old_forum) { create(:forum) }
    let(:message) { create(:message) }
    let(:mail) do
      ThreadMovedMailer.thread_moved(user, message.thread,
                                     old_forum, message.forum,
                                     message_path(message.thread, message)).deliver_now
    end

    it 'renders the subject as notifications.thread_moved' do
      expect(mail.subject).to eq(I18n.t('notifications.thread_moved',
                                        subject: message.subject,
                                        old_forum: old_forum.name,
                                        new_forum: message.forum.name))
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'links to the message' do
      expect(mail.body.encoded).to match(message_path(message.thread, message))
    end
  end
end

# eof
