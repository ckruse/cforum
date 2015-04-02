# -*- coding: utf-8 -*-

class Admin::CfSettingsController < ApplicationController
  authorize_controller { authorize_admin }

  # GET /collections/1/edit
  def edit
    @settings = CfSetting.where(user_id: nil, forum_id: nil).first || CfSetting.new
  end

  # PUT /collections/1
  # PUT /collections/1.json
  def update
    @settings = CfSetting.where(user_id: nil, forum_id: nil).first || CfSetting.new
    @settings.options ||= {}

    params[:settings].each do |k, v|
      if v == '_DEFAULT_'
        @settings.options.delete(k)
      else
        @settings.options[k] = v
      end
    end

    @settings.options_will_change!

    respond_to do |format|
      if @settings.save
        format.html { redirect_to admin_cf_settings_url, notice: t("admin.settings.updated") }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @settings.errors, status: :unprocessable_entity }
      end
    end
  end
end

# eof
