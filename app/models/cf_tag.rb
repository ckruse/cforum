# -*- encoding: utf-8 -*-

class CfTag < ActiveRecord::Base
  self.primary_key = 'tag_id'
  self.table_name  = 'tags'

  has_many :tags_threads, class_name: 'CfTagThread', :foreign_key => :tag_id, :dependent => :destroy
  has_many :threads, class_name: 'CfThread', :through => :tags_threads
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  attr_accessible :tag_id, :tag_name, :forum_id, :slug

  validates_presence_of :tag_name, :forum_id
  validates :tag_name, length: {:in => 2..50}

  def to_param
    slug
  end

  before_create do |t|
    t.slug = t.tag_name.parameterize
  end
end

# eof
