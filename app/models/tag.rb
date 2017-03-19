# -*- encoding: utf-8 -*-

class Tag < ApplicationRecord
  self.primary_key = 'tag_id'
  self.table_name  = 'tags'

  has_many :message_tags, foreign_key: :tag_id, dependent: :destroy
  has_many :messages, through: :message_tags
  belongs_to :forum

  has_many :synonyms, class_name: 'TagSynonym', foreign_key: :tag_id

  validates_presence_of :forum_id
  validates :tag_name, length: { in: 2..50 }, presence: true, uniqueness: { scope: :forum_id }

  def to_param
    slug
  end

  before_create do |t|
    t.slug = t.tag_name.to_url
  end
end

# eof
