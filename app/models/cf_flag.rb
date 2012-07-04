class CfFlag < ActiveRecord::Base
  self.primary_key = 'flag_id'
  self.table_name  = 'cforum.message_flags'

  belongs_to :message, class_name: 'CfMessage', :foreign_key => :message_id

  attr_accessible :message_id, :flag, :value
end