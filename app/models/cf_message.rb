# -*- encoding: utf-8 -*-

class CfMessage < ActiveRecord::Base
  include ParserHelper

  QUOTE_CHAR = "\u{ECF0}"

  self.primary_key = 'message_id'
  self.table_name  = 'messages'

  belongs_to :owner, class_name: 'CfUser', :foreign_key => :user_id
  belongs_to :thread, class_name: 'CfThread', :foreign_key => :thread_id
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  has_many :messages_tags, class_name: 'CfMessageTag', :foreign_key => :message_id, :dependent => :destroy
  has_many :tags, class_name: 'CfTag', :through => :messages_tags

  attr_accessor :messages, :attribs, :parent_level

  validates :author, length: { :in => 2..60 }
  validates :subject, length: { :in => 4..250 }
  validates :content, length: { :in => 10..12288 }

  validates :email, length: {:in => 2..60 }, email: true, allow_blank: true
  validates :homepage, length: {:in => 2..250 }, allow_blank: true, http_url: true

  has_one :close_vote, -> { where(vote_type: false) }, class_name: CfCloseVote, foreign_key: :message_id
  has_one :open_vote, -> { where(vote_type: true) }, class_name: CfCloseVote, foreign_key: :message_id

  validates_presence_of :forum_id, :thread_id

  after_initialize do
    self.flags ||= {} if attributes.has_key? 'flags'
    self.attribs ||= {'classes' => []}
  end

  # default_scope do
  #   where("deleted = false")
  # end

  def delete_with_subtree
    update_attributes(deleted: true)

    messages.each do |m|
      m.delete_with_subtree
    end
  end

  def restore_with_subtree
    update_attributes(deleted: false)

    messages.each do |m|
      m.restore_with_subtree
    end
  end

  def flag_with_subtree(flag, value)
    flags_will_change!
    flags[flag] = value
    save

    messages.each do |m|
      m.flag_with_subtree(flag, value)
    end
  end

  def del_flag_with_subtree(flag)
    flags_will_change!
    flags.delete(flag)
    save

    messages.each do |m|
      m.del_flag_with_subtree(flag)
    end
  end


  def subject_changed?
    return false if parent_id.blank?

    if parent_level.blank?
      self.parent_level = CfMessage.find! parent_id
    end

    parent_level.subject != subject
  end

  def open?
    flags["no-answer"] != "yes" and flags["no-answer-admin"] != 'yes'
  end
end

# eof
