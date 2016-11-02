# -*- encoding: utf-8 -*-

class Subscription < ActiveRecord::Base
  self.primary_key = 'subscription_id'
  self.table_name = 'subscriptions'

  belongs_to :user
  belongs_to :message

  validates_presence_of :user_id, :message_id
  validates_uniqueness_of :message_id, scope: :user_id
end

# eof
