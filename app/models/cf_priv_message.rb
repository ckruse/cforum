# -*- encoding: utf-8 -*-

class CfPrivMessage < ActiveRecord::Base
  self.primary_key = 'priv_message_id'
  self.table_name  = 'priv_messages'

  attr_accessible :priv_message_id, :sender_id, :recipient_id,
    :owner_id, :is_read, :subject, :body,
    :created_at, :updated_at

  belongs_to :sender, class_name: 'CfUser', :foreign_key => :sender_id
  belongs_to :recipient, class_name: 'CfUser', :foreign_key => :recipient_id
  belongs_to :owner, class_name: 'CfUser', :foreign_key => :owner_id

  validates :subject, presence: true, length: {in: 2..250}
  validates :body, presence: true, length: {in: 5..12288}

  validates :sender_id, presence: true
  validates :recipient_id, presence: true
  validates :owner_id, presence: true
end

# eof
