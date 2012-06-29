class CfThread
  include MongoMapper::Document

  set_collection_name :threads

  key :tid, String
  key :archived, Boolean

  one :message, :class_name => 'CfMessage'

  def find_message(mid, msg = nil)
    msg = message if msg.nil?
    return msg if msg.id == mid

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

end

# eof
