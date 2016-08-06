# -*- encoding: utf-8 -*-

class Message < ActiveRecord::Base
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
  has_many :tags, ->{ order(:tag_name) }, through: :message_tags

  has_many :versions, ->{ order(message_version_id: :desc) }, class_name: 'MessageVersion', foreign_key: :message_id

  attr_accessor :messages, :attribs, :parent_level

  validates_presence_of :author, message: I18n.t('messages.error_present', min: 2, max: 60)
  validates_length_of :author, in: 2..60, allow_blank: true, message: I18n.t('messages.error_present', min: 2, max: 60)

  validates_presence_of :subject, message: I18n.t('messages.error_present', min: 4, max: 250)
  validates_length_of :subject, in: 4..250, allow_blank: true, message: I18n.t('messages.error_present', min: 4, max: 250)

  validates_presence_of :content, message: I18n.t('messages.error_present', min: 10, max: 12288)
  validates_length_of :content, in: 10..12288, allow_blank: true, message: I18n.t('messages.error_present', min: 10, max: 12288)

  validates :email, length: {in: 6..60 }, email: true, allow_blank: true
  validates :homepage, length: {in: 2..250 }, allow_blank: true, url: {allow_blank: true, allow_nil: true, message: I18n.t("messages.error_url")}
  validates :problematic_site, length: {in: 2..250 }, allow_blank: true, url: {allow_blank: true, allow_nil: true, message: I18n.t("messages.error_url")}

  has_many :votes, class_name: 'CloseVote', foreign_key: :message_id

  has_many :message_references, ->{ order(created_at: :desc) }, class_name: 'MessageReference', foreign_key: :dst_message_id

  has_one :cite, foreign_key: :message_id

  validates_presence_of :forum_id, :thread_id

  after_initialize do
    self.flags ||= {} if attributes.has_key? 'flags'
    self.attribs ||= {'classes' => []}
  end

  # default_scope do
  #   where("deleted = false")
  # end

  def references(forums, lim = nil)
    fids = forums.map { |f| f.forum_id }
    @references ||= message_references.select { |ref| not ref.src_message.deleted }
    refs = @references.select { |ref| fids.include?(ref.src_message.forum_id) }

    if lim
      refs[0..lim]
    else
      refs
    end
  end

  def close_vote
    votes.each do |v|
      return v if v.vote_type == false
    end

    nil
  end

  def open_vote
    votes.each do |v|
      return v if v.vote_type == true
    end

    nil
  end

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

  def all_answers(&block)
    messages.each do |m|
      block.call(m)
      m.all_answers(&block)
    end
  end

  def subject_changed?
    return false if parent_id.blank?

    if parent_level.blank?
      self.parent_level = Message.find parent_id
    end

    parent_level.subject != subject
  end

  def open?
    # admin decisions overrule normal decisions
    unless flags["no-answer-admin"].blank?
      return true if flags["no-answer-admin"] != 'yes'
      return false if flags["no-answer-admin"] == 'yes'
    end

    flags["no-answer"] != "yes"
  end

  def score
    upvotes - downvotes
  end

  def no_votes
    upvotes + downvotes
  end

  def serializable_hash(options = {})
    options ||= {}
    options[:except] ||= []
    options[:except] += [:uuid, :ip]
    super(options)
  end

  def audit_json
    as_json(include: {thread: {include: :forum}})
  end

  def get_mentions
    if flags['mentions']
      if flags['mentions'].is_a?(Array)
        return flags['mentions']
      else
        return JSON.parse(flags['mentions'])
      end
    end

    return nil
  end
end

# eof
