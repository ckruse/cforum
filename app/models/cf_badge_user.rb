# -*- coding: utf-8 -*-

class CfBadgeUser < ActiveRecord::Base
  self.primary_key = 'badge_user_id'
  self.table_name  = 'badges_users'

  belongs_to :user, class_name: CfUser
  belongs_to :badge, class_name: CfBadge
end

# eof
