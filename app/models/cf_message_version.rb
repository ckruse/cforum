# -*- encoding: utf-8 -*-

class CfMessageVersion < ActiveRecord::Base
  self.primary_key = 'message_version_id'
  self.table_name  = 'message_versions'

  belongs_to :user
  belongs_to :message, class_name: 'CfMessage', foreign_key: :message_id

  def diff_content
    subject + "\n\n" + content
  end
end

# eof
