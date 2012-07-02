# -*- encoding: utf-8 -*-

class CfThread
  include Mongoid::Document

  #set_collection_name :threads
  store_in collection: "threads"

  field :_id, type: String, default: ->{ CfThread.gen_id(self) if self.message and self.message.created_at and self.message.subject }
  field :tid, type: String
  field :archived, type: Boolean

  embeds_one :message, :class_name => 'CfMessage'

  index({ tid: 1 }, { unique: true })
  index({ archived: 1 })
  index({ 'message.created' => 1 })

  def find_message(mid, msg = nil)
    msg = message if msg.nil?
    return msg if msg.id.to_s == mid.to_s

    unless msg.messages.blank?
      msg.messages.each do |m|
        found = find_message(mid, m)
        return found if found
      end
    end

    nil
  end

  def sort_tree(msg = nil)
    msg = message if msg.nil?

    unless msg.messages.blank?
      msg.messages.sort! {|a,b| b.created_at <=> a.created_at }

      msg.messages.each do |m|
        sort_tree(m)
      end
    end
  end

  TO_URI_MAP = [
    {:rx => /[äÄ]/, :replacement => 'ae'},
    {:rx => /[öÖ]/, :replacement => 'oe'},
    {:rx => /[üÜ]/, :replacement => 'ue'},
    {:rx => /ß/,    :replacement => 'ss'},
    {:rx => /[ÀÁÂÃÅÆàáâãåæĀāĂăĄą]/, :replacement => 'a'},
    {:rx => /[ÇçĆćĈĉĊċČč]/, :replacement => 'c'},
    {:rx => /[ÐĎďĐđ]/, :replacement => 'd'},
    {:rx => /[ÈÉÊËèéêëĒēĔĕĖėĘęĚě]/, :replacement => 'e'},
    {:rx => /[ÌÍÎÏìíîï]/, :replacement => 'i'},
    {:rx => /[Ññ]/, :replacement => 'n'},
    {:rx => /[ÒÓÔÕ×Øòóôõø]/, :replacement => 'o'},
    {:rx => /[ÙÚÛùúû]/, :replacement => 'u'},
    {:rx => /[Ýýÿ]/, :replacement => 'y'}
  ]
  def self.gen_id(thread)
    now = thread.message.created_at
    now = Time.now if now.nil?

    id = now.strftime("/%Y/") + now.strftime("%b").downcase + now.strftime("/%d/")

    subject = thread.message.subject.tr(' ','-')
    subject.downcase!

    TO_URI_MAP.each do |map|
      subject.gsub!(map[:rx], map[:replacement])
    end

    subject.gsub!(/[^a-zA-Z0-9.$%;,_*-]/,'-')

    subject.gsub!(/-{2,}/,'-')
    subject.gsub!(/-+$/,'')
    subject.gsub!(/^-+/,'')

    subject = subject[0..120]+"..." if subject.length > 120

    id + subject
  end


  def self.make_id(year, mon = nil, day = nil, tid = nil)
    if year.is_a?(Hash)
      '/' + year[:year] + '/' + year[:mon] + '/' + year[:day] + '/' + year[:tid]
    else
      '/' + year + '/' + mon + '/' + day + '/' + tid
    end
  end
end

# eof
