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

      unless messages.blank?
        messages.each do |m|
          return found if found = find_message(mid, m)
        end
      end
    end
  end
end

# eof
