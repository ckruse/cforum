class CfModerator < ActiveRecord::Base
  self.primary_key = 'moderator_id'
  self.table_name  = 'cforum.moderators'

  belongs_to :user, class_name: 'CfUser', :foreign_key => :user_id
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  attr_accessible :user_id, :forum_id
end


# eof