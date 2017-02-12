# -*- encoding: utf-8 -*-

class PrivMessage < ApplicationRecord
  include ParserHelper

  self.primary_key = 'priv_message_id'
  self.table_name  = 'priv_messages'

  belongs_to :sender, class_name: 'User', foreign_key: :sender_id
  belongs_to :recipient, class_name: 'User', foreign_key: :recipient_id
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id

  validates_length_of :subject, allow_blank: false, in: 2..250
  validates_length_of :body, allow_blank: false, in: 5..12_288

  validates :sender_id, presence: true, on: :create
  validates :recipient_id, presence: true, on: :create
  validates :owner_id, presence: true

  validates_presence_of :sender_name, :recipient_name

  def partner(myself)
    sender_id == myself.user_id ? recipient_name : sender_name
  end

  def partner_id(myself)
    sender_id == myself.user_id ? recipient_id : sender_id
  end

  def partner_user(myself)
    sender_id == myself.user_id ? recipient : sender
  end
end

# eof
