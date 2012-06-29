class CfAuthor
  include MongoMapper::EmbeddedDocument

  key :username, String
  key :name, String
  key :email, String
  key :homepage, String

  key :user_id, ObjectId
  belongs_to :user, :class_name => 'CfUser'

  validates :name, :presence => true, :length => { :in => 2..60 }
  validates :email, :presence => true, :email => true
end
