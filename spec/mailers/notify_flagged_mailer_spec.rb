require 'rails_helper'

RSpec.describe NotifyFlaggedMailer, type: :mailer do
  include CForum::Tools

  describe 'new flagged' do
    let(:user) { create(:user) }
    let(:message) { create(:message, flags: { flagged: 'illegal' }) }
    let(:mail) do
      NotifyFlaggedMailer.new_flagged(user, message,
                                      message_path(message.thread, message)).deliver_now
    end

    it 'renders the subject as plugins.flag_plugin.message_has_been_flagged' do
      expect(mail.subject).to eq(I18n.t('plugins.flag_plugin.message_has_been_flagged',
                                        subject: message.subject,
                                        author: message.author))
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
