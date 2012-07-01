class CfThread
  include Mongoid::Document

  #set_collection_name :threads
  store_in collection: "threads"

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

  def to_param
    id[1..-1]
  end

end

# eof
