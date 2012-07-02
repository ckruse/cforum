# -*- encoding: utf-8 -*-

class CfThread
  include Mongoid::Document

  #set_collection_name :threads
  store_in collection: "threads"

  field :_id, type: String, default: ->{ CfThread.gen_id(self) if self.message and self.message.created_at and self.message.subject }
  field :tid, type: String
  field :archived, type: Boolean, default: false

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

  def self.gen_id(thread)
    now = thread.message.created_at
    now = Time.now if now.nil?

    now.strftime("/%Y/%b/%d/").downcase + thread.message.subject.parameterize
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
