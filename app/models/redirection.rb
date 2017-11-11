class Redirection < ApplicationRecord
  self.primary_key = 'redirection_id'

  validates :path, :destination, :http_status, presence: true
end

# eof
