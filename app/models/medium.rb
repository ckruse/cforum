class Medium < ApplicationRecord
  self.primary_key = 'medium_id'
  self.table_name  = 'media'

  belongs_to :owner, class_name: 'User'

  validates :filename, :orig_name, :content_type, presence: true

  def to_param
    filename
  end

  def self.path
    Rails.root + 'public/uploads'
  end

  def self.medium_path
    path + 'medium'
  end

  def self.thumb_path
    path + 'thumb'
  end

  def full_path(style = :orig)
    case style
    when :orig then self.class.path + filename
    when :thumb then self.class.thumb_path + filename
    when :medium then self.class.medium_path + filename
    end
  end

  def self.gen_filename(orig_name = nil)
    path = self.path
    i = 0
    exists = false
    fname = nil

    while i < 15 && !exists
      fname = SecureRandom.uuid

      if orig_name.present? && orig_name =~ /\.([a-zA-Z0-9]+)$/
        fname << '.' + Regexp.last_match(1).downcase
      end

      begin
        i += 1
        fd = File.open(path + fname, File::WRONLY | File::EXCL | File::CREAT)
        fd.close
        return path, fname
      rescue Errno::EEXIST
        next
      end

    end

    nil
  end

  after_destroy do |_record|
    %i[orig medium thumb].each do |style|
      fname = full_path(style)
      File.unlink(fname) if File.exist?(fname) && File.writable?(fname)
    end
  end
end

# eof
