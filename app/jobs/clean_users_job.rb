class CleanUsersJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    users = User.where("confirmed_at IS NULL AND confirmation_sent_at <= NOW() - INTERVAL '7 days'")
    users.each do |u|
      Rails.logger.info 'CleanupUsersTask: deleting user ' + u.username +
                        ' because it is unconfirmed for longer than 7 days'

      User.transaction do
        audit(u, 'autodestroy', nil)
        u.destroy
      end
    end
  end
end

# eof
