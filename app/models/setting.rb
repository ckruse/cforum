class Setting < ApplicationRecord
  self.primary_key = 'setting_id'
  self.table_name  = 'settings'

  belongs_to :forum
  belongs_to :user, foreign_key: :user_id

  validates :options, setting: true

  after_initialize do
    self.options ||= {} if attributes.key? 'options'
  end

  def conf(nam)
    vals = options
    vals ||= {}

    vals[nam.to_s] || ConfigManager::DEFAULTS[nam]
  end
end

# eof
