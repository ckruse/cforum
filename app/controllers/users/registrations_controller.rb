# -*- coding: utf-8 -*-

class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :setup_negative_captcha, only: [:new, :create]

  def create
    if @captcha.valid?
      build_resource(sign_up_params)

      resource.username = @captcha.values[:username]
      resource.email = @captcha.values[:email]
      resource.password = @captcha.values[:password]
      resource.password_confirmation = @captcha.values[:password_confirmation]

      resource.save

      yield resource if block_given?

      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      # Values dont pass, but that's good
      flash[:notice] = @captcha.error if @captcha.error
      render :action => 'new'
    end

    audit(resource, 'create') if resource.errors.empty?
  end

  private

  def setup_negative_captcha
    @captcha = NegativeCaptcha.new(
      secret: Rails.application.config.negative_captcha_secret,
      spinner: request.remote_ip,
      # Whatever fields are in your form
      fields: [:username, :email, :password, :password_confirmation],
      css: "display: none",
      params: params
    )
  end
end

# eof
