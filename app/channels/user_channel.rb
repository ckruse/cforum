# -*- coding: utf-8 -*-

class UserChannel < ApplicationCable::Channel
  def subscribed
    reject if current_user.blank?
    stream_from "users/#{current_user.user_id}"
  end
end

# eof
