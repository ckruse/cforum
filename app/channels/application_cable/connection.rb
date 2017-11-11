module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.username if current_user.present?
    end

    private

    def find_verified_user
      # no user id given
      return if env['warden'].user.blank?

      # user id given, find it (will fail on error)
      env['warden'].user
    end
  end
end

# eof
