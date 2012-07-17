class CfForum < ActiveRecord::Base
  self.primary_key = 'forum_id'
  self.table_name  = 'cforum.forums'

  has_many :threads, class_name: 'CfThread'

  has_many :forum_mods, class_name: 'CfModerator', :foreign_key => :forum_id
  has_many :moderators, class_name: 'CfUser', :through => :forum_mods, :source => :user

  attr_accessible :forum_id, :slug, :name, :short_name, :description, :updated_at, :created_at

  validates :slug, presence: true, uniqueness: true, length: {:in => 3..20}, allow_blank: false, format: {with: /^[a-z0-9_-]+$/}
  validates :name, presence: true, length: {:minimum => 3}, allow_blank: false
  validates :short_name, presence: true, length: {:in => 3..50}

  def to_param
    slug
  end
end

# eof
