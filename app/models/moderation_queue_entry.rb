# -*- coding: utf-8 -*-

class ModerationQueueEntry < ApplicationRecord
  include ParserHelper

  self.primary_key = 'moderation_queue_entry_id'
  self.table_name = 'moderation_queue'

  REASONS = %w[off-topic not-constructive illegal duplicate custom spam].freeze
  ACTIONS = %w[close delete no-archive none].freeze

  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :message_id, presence: true, uniqueness: true

  validates_presence_of :resolution, :closer_name, :closer_id, if: :cleared?
  validates :resolution_action, presence: true, inclusion: { in: ACTIONS }, if: :cleared?

  validates_presence_of :duplicate_url, if: :duplicate?
  validates_presence_of :custom_reason, if: :custom?

  belongs_to :closer, class_name: 'User'
  belongs_to :message

  def duplicate?
    reason == 'duplicate'
  end

  def custom?
    reason == 'custom'
  end

  def md_content
    resolution
  end

  def l_resolution_action
    I18n.t('moderation_queue.actions.' + resolution_action)
  end
end

# eof
