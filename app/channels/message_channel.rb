class MessageChannel < ApplicationCable::Channel
  def subscribed
    forum = Forum.where(slug: params[:forum]).first
    reject if forum.blank?
    reject unless forum.read?(current_user)
    stream_from "messages/#{forum.slug}"
  end
end

# eof
