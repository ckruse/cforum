class BroadcastUserJob < ApplicationJob
  queue_as :default

  def perform(event, user_id)
    user = User.find(user_id)

    ActionCable
      .server
      .broadcast("users/#{user.user_id}", event)
  end
end

# eof
