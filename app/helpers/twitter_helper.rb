module TwitterHelper
  def twitter_client
    auth_data = TwitterAuthorization.where(user_id: nil).first

    if auth_data
      @_twitter ||= Twitter::REST::Client.new(consumer_key: Rails.application.config.twitter[:consumer_key],
                                              consumer_secret: Rails.application.config.twitter[:consumer_secret],
                                              access_token: auth_data.token,
                                              access_token_secret: auth_data.secret)
    end

    @_twitter
  end
end

# eof
