# -*- coding: utf-8 -*-

class TwitterAuthorization < ActiveRecord::Base
  self.primary_key = 'twitter_authorization_id'
  self.table_name = 'twitter_authorizations'

  validates_presence_of :token, :secret
  validates_uniqueness_of :user_id

  belongs_to :user
end

# eof
