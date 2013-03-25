# -*- coding: utf-8 -*-

class AcceptPluginController < ApplicationController
  ACCEPTING_MESSAGE    = "accepting_message"
  ACCEPTED_MESSAGE     = "accepted_message"

  def accept
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:forum, :messages => [:owner, :tags]).includes(:messages => :owner).where(std_conditions(@id)).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.nil?

    if @thread.acceptance_forbidden?(current_user, cookies[:cforum_user])
      flash[:error] = t('messages.only_op_may_accept')
      redirect_to cf_message_url(@thread, @message)
      return
    end

    notification_center.notify(ACCEPTING_MESSAGE, @thread, @message)
    CfMessage.transaction do
      @message.flags['accepted'] = @message.flags['accepted'] == 'yes' ? 'no' : 'yes'
      @message.save

      unless @message.user_id.blank?
        if @message.flags['accepted'] == 'yes'
          @thread.messages.each do |m|
            if m.message_id != @message.message_id and m.flags['accepted'] == 'yes'
              m.flags.delete('accepted')
              m.save

              if not m.user_id.blank?
                scores = CfScore.where(user_id: m.user_id, message_id: m.message_id).all
                scores.each { |score| score.destroy } if not scores.blank?
              end
            end
          end

          CfScore.create!(
            user_id: @message.user_id,
            message_id: @message.message_id,
            value: conf('accept_value', 15).to_i
          )
        else
          scores = CfScore.where(user_id: @message.user_id, message_id: @message.message_id).all
          scores.each { |score| score.destroy } if not scores.blank?
        end
      end
    end
    notification_center.notify(ACCEPTED_MESSAGE, @thread, @message)

    redirect_to cf_message_url(@thread, @message), notice: (@message.flags['accepted'] == 'yes' ? t('messages.accepted') : t('messages.unaccepted'))
  end
end

# ApplicationController.init_hooks << Proc.new do |app_controller|
#   accept_plugin = HighlightPlugin.new(app_controller)
#   app_controller.notification_center.register_hook(CfThreadsController::SHOW_THREADLIST, accept_plugin)

#   app_controller.notification_center.register_hook(UsersController::SHOWING_SETTINGS, accept_plugin)
#   app_controller.notification_center.register_hook(UsersController::SAVING_SETTINGS, accept_plugin)
# end

# eof
