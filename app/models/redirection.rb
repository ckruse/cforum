# -*- coding: utf-8 -*-

class Redirection < ApplicationRecord
  self.primary_key = 'redirection_id'

  validates_presence_of :path, :destination, :http_status
end

# eof
