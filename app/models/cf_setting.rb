class CfSetting < ActiveRecord::Base
  self.primary_key = 'setting_id'
  self.table_name  = 'cforum.settings'

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  belongs_to :user, class_name: 'CfUser', :foreign_key => :user_id

  attr_accessible :setting_id, :forum_id, :user_id, :name,  :value
end

# eof
