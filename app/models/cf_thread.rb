# -*- encoding: utf-8 -*-

class CfThread < ActiveRecord::Base
  self.primary_key = 'thread_id'
  self.table_name  = 'threads'

  attr_accessor :sorted_messages

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  has_many :messages, ->{ order(:created_at) }, class_name: 'CfMessage', foreign_key: :thread_id, dependent: :destroy

  validates :slug, uniqueness: true, allow_blank: false, format: {with: /\A[a-z0-9_\/-]+\z/}
  validates_presence_of :forum_id, :latest_message

  def find_message(mid)
    messages.each do |m|
      return m if m.message_id == mid
    end

    nil
  end

  def find_message!(mid)
    m = find_message(mid)
    raise ActiveRecord::RecordNotFound if m.blank?
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
    raise ActiveRecord::RecordNotFound.new if m.blank?
    m
  end

  attr_accessor :attribs, :accepted

  def message=(msg)
    @message = msg
  end

  def message
    @message = sorted_messages[0] if @message.blank?
    @message
  end

  def gen_tree(direction = 'ascending')
    self.accepted = []
    map = {}

    @sorted_messages = messages.sort do |a,b|
      ret = a.parent_id.to_i <=> b.parent_id.to_i

      if ret == 0
        if direction == 'ascending'
          ret = a.created_at <=> b.created_at
        else
          ret = b.created_at <=> a.created_at
        end

        ret = a.message_id <=> b.message_id if ret == 0
      end

      ret
    end

    @sorted_messages.first.attribs[:level] = 0

    for msg in @sorted_messages
      self.accepted << msg if msg.flags["accepted"] == 'yes'
      @message = msg if msg.parent_id.blank?

      map[msg.message_id] = msg
      msg.messages = [] unless msg.messages

      if msg.parent_id
        if map[msg.parent_id]
          map[msg.parent_id].messages ||= []
          msg.attribs[:level] = map[msg.parent_id].attribs[:level] + 1

          map[msg.parent_id].messages << msg
          msg.parent_level = map[msg.parent_id]
        else
          if @sorted_messages[0].message_id != msg.message_id
            msg.attribs[:level] = 1
            @sorted_messages[0].messages << msg
            msg.parent_level = @sorted_messages[0]
          end
        end
      end
    end
  end

  def self.gen_id(thread, num = nil)
    now = thread.message.created_at
    now = Time.now if now.nil?

    s = now.strftime("/%Y/%b/%d/").gsub(/0(\d)\/$/, '\1/').downcase
    s << num.to_s unless num.blank?
    s << thread.message.subject.to_url

    s.gsub(/[^a-z0-9_\/-]/, '')
  end

  def self.make_id(year, mon = nil, day = nil, tid = nil)
    if year.is_a?(Hash)
      '/' + year[:year].to_s + '/' + year[:mon].to_s + '/' + year[:day].to_s + '/' + year[:tid].to_s
    else
      '/' + year.to_s + '/' + mon.to_s + '/' + day.to_s + '/' + tid.to_s
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
