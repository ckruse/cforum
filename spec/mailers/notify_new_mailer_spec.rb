require 'rails_helper'

RSpec.describe NotifyNewMailer, type: :mailer do
  include CForum::Tools

  describe 'new message' do
    let(:user) { create(:user) }
    let(:parent) { create(:message) }
    let(:message) { create(:message, parent: parent, thread: parent.thread) }
    let(:mail) do
      NotifyNewMailer.new_message(user, message.thread, parent,
                                  message, message_path(message.thread, message),
                                  'foo bar').deliver_now
    end

    it 'renders the subject as RE: message subject' do
      expect(mail.subject).to eq('RE: ' + message.subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'sets the Message-Id' do
      expect(mail).to have_header('Message-Id',
                                  '<t' + message.thread_id.to_s + 'm' +
                                  message.message_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end
    it 'sets the In-Reply-To' do
      expect(mail).to have_header('In-Reply-To',
                                  '<t' + parent.thread_id.to_s + 'm' +
                                  parent.message_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end

    it 'links to the message' do
      expect(mail.body.encoded).to match(message_path(message.thread, message))
    end
  end

  describe 'new answer' do
    let(:user) { create(:user) }
    let(:parent) { create(:message) }
    let(:message) { create(:message, parent: parent, thread: parent.thread) }
    let(:mail) do
      NotifyNewMailer.new_answer(user, message.thread, parent,
                                 message, message_path(message.thread, message),
                                 'foo bar').deliver_now
    end

    it 'renders the subject as RE: message subject' do
      expect(mail.subject).to eq('RE: ' + message.subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'sets the Message-Id' do
      expect(mail).to have_header('Message-Id',
                                  '<t' + message.thread_id.to_s + 'm' +
                                  message.message_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end
    it 'sets the In-Reply-To' do
      expect(mail).to have_header('In-Reply-To',
                                  '<t' + parent.thread_id.to_s + 'm' +
                                  parent.message_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end

    it 'links to the message' do
      expect(mail.body.encoded).to match(message_path(message.thread, message))
    end
  end

  describe 'new mention' do
    let(:user) { create(:user) }
    let(:message) { create(:message) }
    let(:mail) do
      NotifyNewMailer.new_mention(user, message.thread, message,
                                  message_path(message.thread, message),
                                  'foo bar').deliver_now
    end

    it 'renders the subject as RE: message subject' do
      expect(mail.subject).to eq('RE: ' + message.subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'sets the Message-Id' do
      expect(mail).to have_header('Message-Id',
                                  '<t' + message.thread_id.to_s + 'm' +
                                  message.message_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end

    it 'links to the message' do
      expect(mail.body.encoded).to match(message_path(message.thread, message))
    end
  end

  describe 'new cite' do
    let(:user) { create(:user) }
    let(:cite) { create(:cite) }
    let(:mail) { NotifyNewMailer.new_cite(user, cite, cite_url(cite)).deliver_now }

    it 'renders the subject as "cites.new_cite_arrived"' do
      expect(mail.subject).to eq(I18n.t('cites.new_cite_arrived'))
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Rails.application.config.mail_sender])
    end

    it 'sets the Message-Id' do
      expect(mail).to have_header('Message-Id',
                                  '<cite' + cite.cite_id.to_s + '@' + Rails.application.config.mid_host + '>')
    end

    it 'links to the cite' do
      expect(mail.body.encoded).to match(cite_path(cite))
    end
  end
end

# eof
