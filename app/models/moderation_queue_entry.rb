# -*- coding: utf-8 -*-

class ModerationQueueEntry < ApplicationRecord
  self.primary_key = 'moderation_queue_entry_id'
  self.table_name = 'moderation_queue'

  REASONS = %w(off-topic not-constructive illegal duplicate custom spam).freeze

  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :message_id, presence: true, uniqueness: true

  validates_presence_of :resolution, :closer_name, :closer_id, if: :cleared?

  validates_presence_of :duplicate_url, if: :duplicate?
  validates_presence_of :custom_reason, if: :custom?

  belongs_to :closer, class_name: 'User'

  def duplicate?
    reason == 'duplicate'
  end

  def custom?
    reason == 'custom'
  end
end

# eof
