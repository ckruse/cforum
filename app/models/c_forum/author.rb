module CForum
  class Author
    include MongoMapper::EmbeddedDocument

    key :username, String
    key :name, String
    key :email, String
    key :homepage, String

    key :user_id, ObjectId
    belongs_to :user, :class_name => 'CForum::User'
  end
end
