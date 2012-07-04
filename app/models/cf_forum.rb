class CfForum < ActiveRecord::Base
  self.primary_key = 'forum_id'
  self.table_name  = 'cforum.forums'

  has_many :threads, class_name: 'CfThread'

  attr_accessible :forum_id, :slug, :name, :short_name, :description, :updated_at, :created_at

  def to_param
    slug
  end
end

# eof
