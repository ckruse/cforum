# -*- encoding: utf-8 -*-

class CfTagSynonym < ActiveRecord::Base
  self.primary_key = 'tag_synonym_id'
  self.table_name  = 'tag_synonyms'

  belongs_to :tag, class_name: 'CfTag', foreign_key: :tag_id

  attr_accessible :tag_synonym_id, :tag_id, :synonym

  validates_presence_of :tag_id
  validates :synonym, length: {:in => 2..50}, presence: true
end

# eof
