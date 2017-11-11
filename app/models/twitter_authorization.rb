class TwitterAuthorization < ApplicationRecord
  self.primary_key = 'twitter_authorization_id'
  self.table_name = 'twitter_authorizations'

  validates :token, :secret, presence: true
  validates :user_id, uniqueness: true

  belongs_to :user
end

# eof
