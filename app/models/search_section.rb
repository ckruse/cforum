class SearchSection < ApplicationRecord
  self.primary_key = 'search_section_id'
  self.table_name  = 'search_sections'

  validates :name, :position, presence: true

  belongs_to :forum
end

# eof
