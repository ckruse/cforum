# -*- encoding: utf-8 -*-

class CfMessage < ActiveRecord::Base
  QUOTE_CHAR = "\u{ECF0}"

  self.primary_key = 'message_id'
  self.table_name  = 'cforum.messages'

  serialize :flags, ActiveRecord::Coders::Hstore

  belongs_to :owner, class_name: 'CfUser', :foreign_key => :user_id
  belongs_to :thread, class_name: 'CfThread', :foreign_key => :thread_id

  attr_accessible :message_id, :mid, :thread_id, :subject, :content,
    :author, :email, :homepage, :deleted, :user_id, :parent_id,
    :updated_at, :created_at, :upvotes, :downvotes, :forum_id, :flags

  attr_accessor :messages, :attribs

  validates :author, length: { :in => 2..60 }
  validates :subject, length: { :in => 4..64 }
  validates :content, length: { :in => 10..12288 }

  validates :email, email: true

  after_initialize do
    self.flags ||= {} if attributes.has_key? 'flags'
    self.attribs ||= {'classes' => []}
  end

  # default_scope do
  #   where("deleted = false")
  # end

  def delete_with_subtree
    update_attributes(:deleted => true)

    messages.each do |m|
      m.delete_with_subtree
    end
  end

  def restore_with_subtree
    update_attributes(:deleted => false)

    messages.each do |m|
      m.restore_with_subtree
    end
  end
end

# eof
