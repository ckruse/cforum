# -*- encoding: utf-8 -*-

class CfMessage < ActiveRecord::Base
  self.primary_key = 'message_id'
  self.table_name  = 'cforum.messages'

  has_one :owner, class_name: 'CfUser', :foreign_key => :user_id
  has_many :flags, class_name: 'CfFlag'

  belongs_to :thread, class_name: 'CfThread', :foreign_key => :thread_id

  attr_accessible :message_id, :mid, :thread_id, :subject, :content,
    :author, :email, :homepage, :deleted, :user_id, :parent_id,
    :updated_at, :created_at, :upvotes, :downvotes

  attr_accessor :messages

  validates :author, presence: true, length: { :in => 2..60 }
  validates :subject, presence: true, length: { :in => 4..64 }
  validates :content, presence: true, length: { :in => 10..12288 }

  validates :email, email: true

  def self.view_all
    @@view_all
  end
  def self.view_all=(val)
    @@view_all = val
  end
  self.view_all = false
  default_scope do
    self.view_all ? nil : where("deleted = false")
  end
end

# eof
