class CfMessage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :cf_thread

  field :id, type: String
  field :subject, type: String
  field :category, type: String
  field :content, type: String

  field :flags, type: Hash

  embeds_one :author, :class_name => 'CfAuthor'

  embeds_many :messages, :class_name => 'CfMessage'

  validates_presence_of :id, :subject, :category, :content
  validates_associated :author

  validates :subject, :length => { :in => 4..64 }
  validates :category, :length => { :in => 5..20 }
  validates :content, :length => { :in => 10..12288 }

  # necessary because of silly bug
  before_validation(:on => :create) do
    self.created_at = Time.now if self.created_at.nil?
    self.updated_at = Time.now if self.updated_at.nil?
  end

end

# eof
