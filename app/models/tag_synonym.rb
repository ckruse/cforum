class TagSynonym < ApplicationRecord
  self.primary_key = 'tag_synonym_id'
  self.table_name  = 'tag_synonyms'

  belongs_to :tag
  belongs_to :forum

  validates :tag_id, :forum_id, presence: true
  validates :synonym, length: { in: 2..50 }, presence: true
  validates :synonym, uniqueness: { scope: :forum_id }

  def audit_json
    as_json(include: [:tag])
  end
end

# eof
