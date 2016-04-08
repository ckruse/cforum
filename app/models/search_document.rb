# -*- coding: utf-8 -*-

class SearchDocument < ActiveRecord::Base
  self.primary_key = 'search_document_id'
  self.table_name  = 'search_documents'

  belongs_to :user
  belongs_to :forum
  belongs_to :search_section
end

# eof
