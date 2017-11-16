class CfThread < ApplicationRecord
  self.primary_key = 'thread_id'
  self.table_name  = 'threads'

  attr_accessor :sorted_messages

  belongs_to :forum
  has_many :messages, -> { order(:created_at) }, foreign_key: :thread_id, dependent: :destroy

  validates :slug, uniqueness: true, allow_blank: false, format: { with: %r{\A[a-z0-9_/-]+\z} }
  validates :forum_id, :latest_message, presence: true

  def find_message(message_id)
    messages.find { |m| m.message_id == message_id }
  end

  def find_message!(message_id)
    m = find_message(message_id)
    raise ActiveRecord::RecordNotFound if m.blank?
    m
  end

  def find_by_mid(mid)
    messages.find { |m| m.mid == mid }
  end

  def find_by_mid!(mid)
    m = find_by_mid(mid) # rubocop:disable Rails/DynamicFindBy
    raise ActiveRecord::RecordNotFound if m.blank?
    m
  end

  attr_accessor :attribs, :accepted

  attr_writer :message

  def message
    @message = sorted_messages[0] if @message.blank? && sorted_messages.present?
    @message
  end

  def gen_tree(direction = 'ascending')
    self.accepted = []
    map = {}

    @sorted_messages = messages.sort do |a, b|
      ret = a.parent_id.to_i <=> b.parent_id.to_i

      if ret.zero?
        ret = if direction == 'ascending'
                a.created_at <=> b.created_at
              else
                b.created_at <=> a.created_at
              end

        ret = a.message_id <=> b.message_id if ret.zero?
      end

      ret
    end

    @sorted_messages.first.attribs[:level] = 0
    prev = nil

    @sorted_messages.each do |msg|
      accepted << msg if msg.accepted?
      @message = msg if msg.parent_id.blank?

      if prev
        msg.prev = prev
        prev.next = msg
      end
      prev = msg

      map[msg.message_id] = msg
      msg.messages = [] unless msg.messages

      if msg.parent_id
        if map[msg.parent_id]
          map[msg.parent_id].messages ||= []
          msg.attribs[:level] = map[msg.parent_id].attribs[:level] + 1

          map[msg.parent_id].messages << msg
          msg.parent_level = map[msg.parent_id]
        elsif @sorted_messages[0].message_id != msg.message_id
          msg.attribs[:level] = 1
          @sorted_messages[0].messages << msg
          msg.parent_level = @sorted_messages[0]
        end
      end
    end
  end

  def self.gen_id(thread, num = nil)
    now = thread.message.created_at
    now = Time.zone.now if now.nil?

    s = now.strftime('/%Y/%b/%d/').gsub(%r{0(\d)/$}, '\1/').downcase
    s << num.to_s + '-' if num.present?
    s << thread.message.subject.to_s.gsub(/[<>]/, '').to_url

    s.gsub(%r{[^a-z0-9_/-]}, '')
  end

  def self.make_id(opts = {})
    '/' + opts[:year].to_s + '/' + opts[:mon].to_s + '/' + opts[:day].to_s + '/' + opts[:tid].to_s
  end

  after_initialize do
    self.attribs ||= { 'classes' => [] }
    self.flags ||= {} if attributes.key? 'flags'
  end

  def acceptance_forbidden?(usr, uuid)
    forbidden = false

    # current user is not the owner of the message
    if usr.present?
      forbidden = true if (message.user_id != usr.user_id) && !usr.admin?
    elsif message.uuid.blank? # has message not been posted anonymously?
      forbidden = true
    elsif uuid != message.uuid
      forbidden = true
    end

    forbidden
  end

  def audit_json
    as_json(include: %i[messages forum])
  end
end

# eof
