# -*- coding: utf-8 -*-

class CfBadge < ActiveRecord::Base
  include ParserHelper

  self.primary_key = 'badge_id'
  self.table_name  = 'badges'

  has_many :badges_users, class_name: CfBadgeUser, dependent: :delete_all,
           foreign_key: :badge_id
  has_many :users, through: :badges_users

  validates :name, presence: true, length: {in: 2..255}, allow_blank: false
  validates :score_needed, presence: true, numericality: { only_integer: true },
            allow_blank: false
  validates :badge_type, presence: true, allow_blank: false,
            inclusion: { in: %w(custom upvote downvote retag
                               visit_close_reopen create_tag edit_question
                               edit_answer create_tag_synonym
                               create_close_reopen_vote moderator_tools) }
  validates :badge_type, uniqueness: true, unless: "badge_type != 'custom'"
  validates :badge_medal_type, presence: true, allow_blank: false,
            inclusion: { in: %w(bronze silver gold) }

  def to_param
    slug
  end

  def get_content
    description.to_s
  end

  def id_prefix
    ''
  end
end

# eof
