# -*- encoding: utf-8 -*-

class CfTag < ActiveRecord::Base
  self.primary_key = 'tag_id'
  self.table_name  = 'tags'

  has_many :messages_tags, class_name: 'CfMessageTag', :foreign_key => :tag_id, :dependent => :destroy
  has_many :messages, class_name: 'CfMessage', :through => :messages_tags
  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id

  has_many :synonyms, class_name: 'CfTagSynonym', foreign_key: :tag_id

  validates_presence_of :forum_id
  validates :tag_name, length: {:in => 2..50}, presence: true, uniqueness: { scope: :forum_id }

  def to_param
    slug
  end

  before_create do |t|
    t.slug = t.tag_name.parameterize
  end
end

# eof
