class Notification < ApplicationRecord
  include ParserHelper

  self.primary_key = 'notification_id'
  self.table_name  = 'notifications'

  belongs_to :recipient, class_name: 'User', foreign_key: :recipient_id

  validates :subject, presence: true, length: { in: 2..250 }
  validates :path, presence: true, length: { in: 5..250 }

  validates :recipient_id, presence: true
  validates :oid, presence: true
  validates :otype, presence: true

  def md_content
    description
  end

  def md_format
    'markdown'
  end

  def id_prefix
    'notifications'
  end
end

# eof
