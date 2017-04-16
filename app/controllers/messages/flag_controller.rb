# -*- coding: utf-8 -*-

class Messages::FlagController < ApplicationController
  authorize_controller { authorize_forum(permission: :read?) }
  authorize_action(:unflag) { authorize_forum(permission: :moderator?) }

  #
  # flagging
  #

  def flag
    @thread, @message, @id = get_thread_w_post

    unless @message.flags['flagged'].blank?
      redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.already_flagged')
      return
    end

    respond_to do |format|
      format.html
    end
  end

  def flagging
    @thread, @message, @id = get_thread_w_post

    unless @message.flags['flagged'].blank?
      redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.already_flagged')
      return
    end

    unless %w(off-topic not-constructive duplicate custom spam).include?(params[:reason])
      flash.now[:error] = t('plugins.flag_plugin.reason_invalid')
      render :flag
      return
    end

    @message.flags_will_change!

    if params[:reason] == 'duplicate'
      if params[:duplicate_slug].blank? || !(params[:duplicate_slug] =~ /^https?:\/\//)
        flash.now[:error] = t('plugins.flag_plugin.dup_url_needed')
        render :flag
        return
      end

      @message.flags[:flagged_dup_url] = params[:duplicate_slug]

    elsif params[:reason] == 'custom'
      if params[:custom_reason].blank?
        flash.now[:error] = t('plugins.flag_plugin.custom_reason_needed')
        render :flag
        return
      end

      @message.flags[:custom_reason] = params[:custom_reason]
    end

    @message.flags[:flagged] = params[:reason]
    @message.save!

    audit(@message, 'flagged-' + params[:reason])

    peon(class_name: 'NotifyFlaggedTask',
         arguments: {
           type: 'message',
           message_id: @message.message_id
         })

    redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.flagged')
  end

  def unflag
    @thread, @message, @id = get_thread_w_post

    @message.flags.delete('flagged')
    @message.flags.delete('custom_reason')
    @message.flags.delete('flagged_dup_url')
    @message.flags_will_change!
    @message.save!

    audit(@message, 'unflagged')

    redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.unflagged')
  end
end

# eof
