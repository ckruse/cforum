module CForum
  class Thread
    include MongoMapper::Document

    set_collection_name :threads

    key :tid, String
    key :archived, Boolean

    one :message, :class_name => 'CForum::Message'

    def find_message(mid, msg = nil)
      msg = message if msg.nil?
      return msg if msg.id == mid

      unless msg.messages.blank?
        msg.messages.each do |m|
          found = find_message(mid, m)
          return found if found
        end
      end
    end
  end
end

# eof
