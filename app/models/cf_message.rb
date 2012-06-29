class CfMessage
  include MongoMapper::EmbeddedDocument

  key :id, String
  key :subject, String
  key :category, String
  key :content, String

  timestamps!

  key :flags, Hash

  one :author, :class_name => 'CfAuthor'

  many :messages, :class_name => 'CfMessage'

  validates_presence_of :id, :subject, :category, :content
  validates_associated :author

  validates :subject, :length => { :in => 4..64 }
  validates :category, :length => { :in => 5..20 }
  validates :content, :length => { :in => 10..12288 }
end

# eof
