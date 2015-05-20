# -*- coding: utf-8 -*-

class SearchDocument < ActiveRecord::Base
  self.primary_key = 'search_document_id'
  self.table_name  = 'search_documents'

  belongs_to :user, class_name: 'CfUser', foreign_key: :user_id
  belongs_to :search_section
end

# eof
