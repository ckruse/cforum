# -*- encoding: utf-8 -*-

class CfTagSynonym < ActiveRecord::Base
  self.primary_key = 'tag_synonym_id'
  self.table_name  = 'tag_synonyms'

  belongs_to :tag, class_name: 'CfTag', foreign_key: :tag_id
  belongs_to :forum, class_name: 'CfForum', foreign_key: :forum_id

  validates_presence_of :tag_id, :forum_id
  validates :synonym, length: {:in => 2..50}, presence: true
  validates_uniqueness_of :synonym, scope: :forum_id

  def audit_json
    as_json(include: [:tag])
  end
end

# eof
