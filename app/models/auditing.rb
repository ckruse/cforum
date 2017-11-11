class Auditing < ApplicationRecord
  self.primary_key = 'auditing_id'
  self.table_name  = 'auditing'

  belongs_to :user

  validates :relation, :relid, :act, :contents, presence: true
end

# eof
