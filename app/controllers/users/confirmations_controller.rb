class Users::ConfirmationsController < Devise::ConfirmationsController
  alias_method :orig_show, :show

  def show
    @user = User.where(confirmation_token: params[:confirmation_token]).first!
    render 'devise/registrations/show.html'
  end

  def update
    user = User
             .where(confirmation_token: params[:confirmation_token],
                    confirmation_captcha: params[:confirmation_captcha])
             .first

    if user.blank?
      redirect_to root_url, t('devise.could_not_find_appropriate_user')
    else
      orig_show
      audit(resource, 'confirm') if resource.errors.empty?
    end
  end
end

# eof
