# -*- coding: utf-8 -*-

class Medium < ActiveRecord::Base
  self.primary_key = 'medium_id'
  self.table_name  = 'media'

  belongs_to :owner, class_name: CfUser

  validates_presence_of :filename, :orig_name, :content_type

  def to_param
    filename
  end

  def self.path
    Rails.root + 'public/uploads'
  end

  def self.gen_filename(orig_name = nil)
    path = self.path
    i = 0
    exists = false
    fname = nil

    while i < 15 and not exists
      fname = SecureRandom.uuid

      if not orig_name.blank? and orig_name =~ /\.([a-zA-Z0-9]+)$/
        fname << '.' + $1.downcase
      end

      begin
        i += 1
        fd = File.open(path + fname, File::WRONLY|File::EXCL|File::CREAT)
        fd.close
        return path, fname
      rescue
      end

    end

    return nil
  end

  after_destroy do |record|
    path = self.class.path
    fname = path + filename

    begin
      File.unlink(fname) if File.exists?(fname)
    rescue
    end
  end
end

# eof
