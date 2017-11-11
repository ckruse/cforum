require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  include CForum::Tools

  describe 'new notification' do
    let(:user) { create(:user) }
    let(:notification) { create(:notification) }
    let(:mail) do
      NotificationMailer.new_notification(user: user, subject: notification.subject,
                                          body: 'Foo bar')
    end

    it 'renders the subject as defined' do
      expect(mail.subject).to eq(notification.subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Foo bar')
    end
  end
end

# eof
