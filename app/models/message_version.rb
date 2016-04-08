# -*- encoding: utf-8 -*-

class MessageVersion < ActiveRecord::Base
  self.primary_key = 'message_version_id'
  self.table_name  = 'message_versions'

  belongs_to :user
  belongs_to :message

  def diff_content
    subject + "\n\n" + content
  end
end

# eof
