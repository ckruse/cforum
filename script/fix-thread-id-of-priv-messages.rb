#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), '..', 'config', 'boot')
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

PrivMessage.transaction do
  User.all.each do |usr|
    mails = PrivMessage
              .preload(:sender, :recipient)
              .where('owner_id = ?', usr.user_id)
              .order(:created_at)

    mail_groups = {}
    mail_groups_keys = []
    mails.each do |mail|
      key = mail.subject.gsub(/^Re: /, '') + '-' + mail.partner(usr)
      mail_groups_keys << key if mail_groups[key].blank?

      mail_groups[key] ||= []
      mail_groups[key] << mail
    end

    mail_groups_keys.each do |k|
      mail_groups[k] = mail_groups[k].sort_by(&:created_at)
    end

    mail_groups.each do |_, mgroup|
      parent = nil

      mgroup.each do |mail|
        if parent.nil?
          next_val = PrivMessage.connection.select_value("SELECT nextval('priv_messages_thread_id_seq')").to_i
          mail.thread_id = next_val
        else
          mail.thread_id = parent.thread_id
        end

        puts "#{mail.thread_id} #{mail.subject} to #{parent.try(:thread_id)} #{parent.try(:subject)}"

        mail.save!

        parent = mail
      end
    end
  end
end

# eof
