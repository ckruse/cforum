# -*- encoding: utf-8 -*-

class TagSynonym < ActiveRecord::Base
  self.primary_key = 'tag_synonym_id'
  self.table_name  = 'tag_synonyms'

  belongs_to :tag
  belongs_to :forum

  validates_presence_of :tag_id, :forum_id
  validates :synonym, length: {:in => 2..50}, presence: true
  validates_uniqueness_of :synonym, scope: :forum_id

  def audit_json
    as_json(include: [:tag])
  end
end

# eof
