class Message < ApplicationRecord
  include ParserHelper
  include ScoresHelper

  self.primary_key = 'message_id'
  self.table_name  = 'messages'

  belongs_to :owner, class_name: 'User', foreign_key: :user_id
  belongs_to :editor, class_name: 'User', foreign_key: :editor_id
  belongs_to :thread, class_name: 'CfThread', foreign_key: :thread_id
  belongs_to :forum
  belongs_to :parent, class_name: 'Message', foreign_key: :parent_id

  has_many :message_tags, foreign_key: :message_id, dependent: :destroy
  has_many :tags, -> { order(:tag_name) }, through: :message_tags

  has_many :versions, -> { order(message_version_id: :desc) }, class_name: 'MessageVersion', foreign_key: :message_id

  has_many :subscriptions, dependent: :delete_all

  attr_accessor :messages, :attribs, :parent_level, :prev, :next

  validates :author, length: { in: 2..60,
                               allow_blank: false,
                               message: I18n.t('messages.error_present', min: 2, max: 60) }

  validates :subject, length: { in: 4..250, allow_blank: false,
                                message: I18n.t('messages.error_present', min: 4, max: 250) }

  validates :content, length: { in: 10..12_288, allow_blank: false, message: I18n.t('messages.error_present',
                                                                                    min: 10, max: 12_288) }

  validates :email, length: { in: 6..60 }, email: true, allow_blank: true
  validates :homepage, length: { in: 2..250 }, allow_blank: true, url: { allow_blank: true,
                                                                         allow_nil: true,
                                                                         message: I18n.t('messages.error_url') }

  validates :problematic_site, length: { in: 2..250 }, allow_blank: true, url: { allow_blank: true,
                                                                                 allow_nil: true,
                                                                                 message: I18n.t('messages.error_url') }

  has_many :votes, class_name: 'CloseVote', foreign_key: :message_id, dependent: :delete_all

  has_many :message_references, -> { order(created_at: :desc) },
           class_name: 'MessageReference', foreign_key: :dst_message_id

  has_many :moderation_queue_entries, dependent: :delete_all
  has_one :open_moderation_queue_entry, -> { where(cleared: false) }, class_name: 'ModerationQueueEntry'

  has_one :cite, foreign_key: :message_id, dependent: :nullify

  validates :forum_id, :thread_id, presence: true

  after_initialize do
    self.flags ||= {} if attributes.key? 'flags'
    self.attribs ||= { 'classes' => [] }
  end

  # default_scope do
  #   where("deleted = false")
  # end

  def references(forums, lim = -1)
    fids = forums.map(&:forum_id)
    @references ||= message_references.reject { |ref| ref.src_message.deleted }
    refs = @references.select { |ref| fids.include?(ref.src_message.forum_id) }
    refs[0..lim]
  end

  def close_vote
    votes.find { |v| v.vote_type == false }
  end

  def open_vote
    votes.find { |v| v.vote_type == true }
  end

  def delete_with_subtree
    update_attributes(deleted: true)
    messages.each(&:delete_with_subtree)
  end

  def restore_with_subtree
    update_attributes(deleted: false)
    messages.each(&:restore_with_subtree)
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

  def all_answers(&block)
    messages.each do |m|
      yield(m)
      m.all_answers(&block)
    end
  end

  def subject_changed?
    return false if parent_id.blank?
    self.parent_level ||= Message.find parent_id
    parent_level.subject != subject
  end

  def tags_changed?
    return true if parent_id.blank?
    self.parent_level ||= Message.find parent_id
    ((tags + parent_level.tags) - (tags & parent_level.tags)).present?
  end

  def day_changed?(msg = nil)
    return true if parent_id.blank? && msg.blank?

    if msg.blank?
      self.parent_level ||= Message.find parent_id
      msg = parent_level
    end

    msg.created_at.to_date != created_at.to_date
  end

  def open?
    # admin decisions overrule normal decisions
    return flags['no-answer-admin'] != 'yes' if flags['no-answer-admin'].present?
    flags['no-answer'] != 'yes'
  end

  def score
    upvotes - downvotes
  end

  def no_votes
    upvotes + downvotes
  end

  def accepted?
    flags['accepted'] == 'yes'
  end

  def serializable_hash(options = {})
    options ||= {}
    options[:except] ||= []
    options[:except] += %i[uuid ip]
    super(options)
  end

  def audit_json
    as_json(include: { thread: { include: :forum } })
  end

  def md_mentions
    if flags['mentions']
      return flags['mentions'] if flags['mentions'].is_a?(Array)
      return JSON.parse(flags['mentions'])
    end

    nil
  end

  def get_created_at # rubocop:disable Naming/AccessorMethodName
    created_at || Time.zone.now
  end
end

# eof
