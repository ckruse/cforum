class UserChannel < ApplicationCable::Channel
  def subscribed
    reject if current_user.blank? || current_user.try(:user_id).blank?
    stream_from "users/#{current_user.user_id}"
  end
end

# eof
