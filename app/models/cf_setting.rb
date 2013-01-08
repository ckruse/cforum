# -*- encoding: utf-8 -*-

class CfSetting < ActiveRecord::Base
  self.primary_key = 'setting_id'
  self.table_name  = 'settings'

  serialize :options, ActiveRecord::Coders::Hstore

  belongs_to :forum, class_name: 'CfForum', :foreign_key => :forum_id
  belongs_to :user, class_name: 'CfUser', :foreign_key => :user_id

  attr_accessible :setting_id, :forum_id, :user_id, :options

  validates :options, setting: true

  after_initialize do
    self.options ||= {} if attributes.has_key? 'options'
  end

  def conf(nam, default = nil)
    vals = options
    vals ||= {}

    vals[nam.to_s] || default
  end

end

# eof
