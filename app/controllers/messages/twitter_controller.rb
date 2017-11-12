class Messages::TwitterController < ApplicationController
  authorize_controller { authorize_forum(permission: :moderator?) }
  before_action :load_ressource

  include TwitterHelper

  def new
    @tweet_text = t('plugins.twitter.twitter_text',
                    subject: @message.subject,
                    author: @message.author,
                    url: message_url(@thread, @message))
  end

  def create
    @tweet_text = params[:tweet_text]
    has_error = params[:tweet_text].blank?

    unless has_error
      begin
        twitter_client.update params[:tweet_text]
      rescue Twitter::Error::Unauthorized => e
        has_error = true
        flash.now[:error] = e.message
      end
    end

    if has_error
      render :new, notice: t('plugins.twitter.tweeted')
    else
      redirect_to message_url(@thread, @message)
    end
  end

  def load_ressource
    @thread, @message, @id = get_thread_w_post
  end
end

# eof
