# -*- coding: utf-8 -*-

class Badge < ActiveRecord::Base
  include ParserHelper

  # this is the list of known rights/permissions
  UPVOTE                   = "upvote"
  DOWNVOTE                 = "downvote"
  FLAG                     = "flag"
  RETAG                    = "retag"
  VISIT_CLOSE_REOPEN       = "visit_close_reopen"
  CREATE_TAGS              = "create_tag"
  CREATE_TAG_SYNONYM       = "create_tag_synonym"
  EDIT_QUESTION            = "edit_question"
  EDIT_ANSWER              = "edit_answer"
  CREATE_CLOSE_REOPEN_VOTE = "create_close_reopen_vote"
  MODERATOR_TOOLS          = "moderator_tools"
  SEO_PROFI                = 'seo_profi'

  RIGHTS = [ UPVOTE, DOWNVOTE, FLAG,
             RETAG, VISIT_CLOSE_REOPEN, CREATE_TAGS,
             CREATE_TAG_SYNONYM, EDIT_QUESTION, EDIT_ANSWER,
             CREATE_CLOSE_REOPEN_VOTE, MODERATOR_TOOLS, SEO_PROFI ]

  self.primary_key = 'badge_id'
  self.table_name  = 'badges'

  has_many :badge_users, dependent: :delete_all
  has_many :users, through: :badge_users

  validates :name, presence: true, length: {in: 2..255}, allow_blank: false
  validates :score_needed, numericality: { only_integer: true },
            allow_blank: true
  validates :badge_type, presence: true, allow_blank: false,
            inclusion: { in: %w(custom) + RIGHTS }
  validates :badge_type, uniqueness: true, unless: "badge_type == 'custom'"
  validates :badge_medal_type, presence: true, allow_blank: false,
            inclusion: { in: %w(bronze silver gold) }

  validates :slug, presence: true, allow_blank: false

  def to_param
    slug
  end

  def md_content
    description.to_s
  end

  def id_prefix
    ''
  end

  def unique_users
    unique_users = {}
    badge_users.each do |ub|
      unique_users[ub.user_id] ||= {user: ub.user, created_at: ub.created_at, times: 0}
      unique_users[ub.user_id][:times] += 1
    end

    unique_users.values.sort { |a,b| a[:created_at] <=> b[:created_at] }
  end
end

# eof
