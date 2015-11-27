# -*- coding: utf-8 -*-

class PagesController < ApplicationController
  def help
    @moderators = CfUser.
                  where("admin = true OR user_id IN (SELECT user_id FROM groups_users WHERE group_id IN (SELECT group_id FROM forums_groups_permissions WHERE permission = ?))",
                        CfForumGroupPermission::ACCESS_MODERATE).
                  order(:username)

    @badges = CfBadge.order(:score_needed)
  end
end

# eof
