# -*- encoding: utf-8 -*-

class CfThread < ActiveRecord::Base
  self.primary_key = 'thread_id'
  self.table_name  = 'threads'

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  has_many :messages, class_name: 'CfMessage', :foreign_key => :thread_id, :dependent => :destroy

  attr_accessible :thread_id, :tid, :slug, :forum_id, :archived, :created_at, :updated_at, :sticky, :flags

  validates :slug, uniqueness: true, allow_blank: false, format: {with: /^[a-z0-9_\/-]+$/}
  validates_presence_of :forum_id

  def find_message(mid)
    messages.each do |m|
      return m if m.message_id == mid
    end

    nil
  end

  def find_message!(mid)
    m = find_message(mid)
    raise CForum::NotFoundException.new if m.blank?
    m
  end

  def find_by_mid(mid)
    messages.each do |m|
      return m if m.mid == mid
    end

    nil
  end

  def find_by_mid!(mid)
    m = find_by_mid(mid)
    raise CForum::NotFoundException.new if m.blank?
    m
  end

  attr_accessor :attribs, :accepted

  def message=(msg)
    @message = msg
  end

  def message
    @message = messages[0] if @message.blank?
    @message
  end

  def gen_tree
    messages.sort! do |a,b|
      ret = a.created_at <=> b.created_at
      ret = a.message_id <=> b.message_id if ret == 0

      ret
    end

    map = {}

    messages.each do |msg|
      self.accepted = msg if msg.flags["accepted"] == 'yes'

      map[msg.message_id] = msg
      msg.messages = [] unless msg.messages

      if msg.parent_id
        map[msg.parent_id].messages << msg
        msg.parent_level = map[msg.parent_id]
      end
    end
  end

  def sort_tree(msg = nil)
    msg = message if msg.nil?

    unless msg.messages.blank?
      msg.messages.sort! {|a,b| b.created_at <=> a.created_at }

      msg.messages.each do |m|
        sort_tree(m)
      end
    end
  end

  def self.gen_id(thread, num = nil)
    now = thread.message.created_at
    now = Time.now if now.nil?

    s = now.strftime("/%Y/%b/%d/").downcase
    s << num.to_s unless num.blank?
    s + thread.message.subject.parameterize
  end

  def self.make_id(year, mon = nil, day = nil, tid = nil)
    if year.is_a?(Hash)
      '/' + year[:year] + '/' + year[:mon] + '/' + year[:day] + '/' + year[:tid]
    else
      '/' + year + '/' + mon + '/' + day + '/' + tid
    end
  end

  # default_scope do
  #   where('EXISTS (SELECT thread_id FROM cforum.messages WHERE thread_id = cforum.threads.thread_id AND deleted = false)')
  # end

  # before_create do |t|
  #   t.slug = CfThread.gen_id(t) if t.slug.blank?
  # end

  after_initialize do
    self.attribs ||= {'classes' => []}
    self.flags ||= {} if attributes.has_key? 'flags'
  end

  alias_method :messages_orig, :messages
  def messages
    ret = messages_orig

    if not @generated and not ret.blank?
      @generated = true
      gen_tree
      sort_tree
    end

    ret
  end

  def acceptance_forbidden?(usr, uuid)
    forbidden = false

    # current user is not the owner of the message
    if not usr.blank?
      forbidden = true if message.user_id != usr.user_id and not usr.admin?
    elsif message.uuid.blank? # has message not been posted anonymously?
      forbidden = true
    else
      forbidden = true if uuid != message.uuid
    end

    forbidden
  end
end

# eof
