class ThreadChannel < ApplicationCable::Channel
  def subscribed
    forum = Forum.where(slug: params[:forum]).first
    reject if forum.blank?
    reject unless forum.read?(current_user)
    stream_from "threads/#{forum.slug}"
  end
end

# eof
