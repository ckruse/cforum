class Admin::TwitterController < ApplicationController
  authorize_controller { authorize_admin }

  include TwitterHelper

  def edit
    @twitter_authorization = TwitterAuthorization.where(user_id: nil).first
  end

  def authorize
    rq_token = consumer.get_request_token(oauth_callback: admin_twitter_callback_url)
    session[:token] = rq_token.token
    session[:token_secret] = rq_token.secret
    redirect_to rq_token.authorize_url
  end

  def callback
    request_token = OAuth::RequestToken.new(consumer, session[:token], session[:token_secret])
    access_token = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])

    @twitter_authorization = TwitterAuthorization.where(user_id: nil).first
    @twitter_authorization = TwitterAuthorization.new if @twitter_authorization.blank?

    @twitter_authorization.token = access_token.token
    @twitter_authorization.secret = access_token.secret

    if @twitter_authorization.save
      redirect_to root_url, notice: t('admin.twitter.authorized')
    else
      redirect_to admin_twitter_url, error: t('admin.twitter.authorize_failed')
    end
  end

  def consumer
    @consumer ||= OAuth::Consumer.new(Rails.application.config.twitter[:consumer_key],
                                      Rails.application.config.twitter[:consumer_secret],
                                      site: 'https://api.twitter.com',
                                      scheme: :header)
  end
end

# eof
