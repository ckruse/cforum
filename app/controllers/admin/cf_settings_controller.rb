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
    @settings.options = params[:settings]

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
