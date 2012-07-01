class CfAuthor
  include Mongoid::Document
  embedded_in :cf_message

  field :username, type: String
  field :name, type: String
  field :email, type: String
  field :homepage, type: String

  #field :user_id, ObjectId
  belongs_to :user, :class_name => 'CfUser'

  validates :name, :presence => true, :length => { :in => 2..60 }
  validates :email, :presence => true, :email => true
end
