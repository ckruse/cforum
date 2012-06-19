class Author
  include MongoMapper::EmbeddedDocument

  key :name, String
  key :email, String
  key :homepage, String

  key :user_id, ObjectId
  belongs_to :user
end
