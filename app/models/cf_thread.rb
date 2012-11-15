# -*- encoding: utf-8 -*-

class CfThread < ActiveRecord::Base
  self.primary_key = 'thread_id'
  self.table_name  = 'cforum.threads'

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  has_many :messages, class_name: 'CfMessage', :foreign_key => :thread_id

  attr_accessible :thread_id, :tid, :slug, :forum_id, :archived, :created_at, :updated_at

  def find_message(mid)
    messages.each do |m|
      return m if m.message_id == mid
    end

    nil
  end

  attr_accessor :message

  def gen_tree
    messages.sort! do |a,b|
      ret = a.created_at <=> b.created_at
      ret = a.message_id <=> b.message_id if ret == 0

      ret
    end

    self.message = messages[0]
    map = {}

    messages.each do |msg|
      map[msg.message_id] = msg
      msg.messages = [] unless msg.messages

      if msg.parent_id
        map[msg.parent_id].messages << msg
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

  def self.gen_id(thread)
    now = thread.message.created_at
    now = Time.now if now.nil?

    now.strftime("/%Y/%b/%d/").downcase + thread.message.subject.parameterize
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

  before_create do |t|
    t.slug = CfThread.gen_id(t) if t.slug.blank?
  end
end

# eof
