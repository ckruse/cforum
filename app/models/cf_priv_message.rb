# -*- encoding: utf-8 -*-

class CfPrivMessage < ActiveRecord::Base
  include ParserHelper

  self.primary_key = 'priv_message_id'
  self.table_name  = 'priv_messages'

  belongs_to :sender, class_name: 'CfUser', foreign_key: :sender_id
  belongs_to :recipient, class_name: 'CfUser', foreign_key: :recipient_id
  belongs_to :owner, class_name: 'CfUser', foreign_key: :owner_id

  validates :subject, presence: true, length: {in: 2..250}
  validates :body, presence: true, length: {in: 5..12288}

  validates :sender_id, presence: true, on: :create
  validates :recipient_id, presence: true, on: :create
  validates :owner_id, presence: true

  def partner(myself)
    sender_id == myself.user_id ? recipient_name : sender_name
  end

  def partner_id(myself)
    sender_id == myself.user_id ? recipient_id : sender_id
  end
end

# eof
