# -*- coding: utf-8 -*-

class NoAnswerNoArchivePluginController < ApplicationController
  NO_ANSWER          = "no_answer"
  NO_ANSWERED        = "no_answered"
  NO_ANSWER_REMOVING = "no_answer_removing"
  NO_ANSWER_REMOVED  = "no_answer_removed"

  NO_ARCHIVE          = "no_archive"
  NO_ARCHIVED         = "no_archived"
  NO_ARCHIVE_REMOVING = "no_archive_removing"
  NO_ARCHIVE_REMOVED  = "no_archive_removed"

  def no_answer
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:forum, :messages => [:owner, :tags]).includes(:messages => :owner).where(std_conditions(@id)).first
    raise CForum::NotFoundException.new if @thread.blank?

    @message = @thread.find_message(params[:mid].to_i)
    raise CForum::NotFoundException.new if @message.nil?

    retvals = notification_center.notify(@message.flags['no-answer'] == 'yes' ? NO_ANSWER_REMOVING : NO_ANSWER, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        if @message.flags['no-answer'] == 'yes'
          @message.del_flag_with_subtree('no-answer')
        else
          @message.flag_with_subtree('no-answer', 'yes')
        end
      end

      notification_center.notify(@message.flags['no-answer'] == 'yes' ? NO_ANSWERED : NO_ANSWER_REMOVED, @thread, @message)
    end

    respond_to do |format|
      format.html do
        redirect_to(
          cf_message_url(
            @thread,
            @message,
            :view_all => true
          ),
          notice: I18n.t(
            @message.flags['no-answer'] == 'yes' ? 'plugins.no_answer_no_archive.no_answered' : 'plugins.no_answer_no_archive.no_answer_removed'
          )
        )
      end

      format.json { head :no_content }
    end
  end

  def no_archive
    @id = CfThread.make_id(params)
    @thread = CfThread.preload(:forum).find_by_slug(@id)
    raise CForum::NotFoundException.new if @thread.blank?

    retvals = notification_center.notify(@thread.flags['no-archive'] == 'yes' ? NO_ARCHIVE_REMOVING : NO_ARCHIVE, @thread)

    unless retvals.include?(false)
      CfMessage.transaction do
        if @thread.flags['no-archive'] == 'yes'
          @thread.flags.delete 'no-archive'
        else
          @thread.flags['no-archive'] = 'yes'
        end

        @thread.save
      end

      notification_center.notify(@thread.flags['no-archive'] == 'yes' ? NO_ARCHIVED : NO_ARCHIVE_REMOVED, @thread)
    end

    respond_to do |format|
      format.html do
        redirect_to(
          cf_forum_url(current_forum || 'all'),
          notice: I18n.t(
            @thread.flags['no-archive'] == 'yes' ? 'plugins.no_answer_no_archive.no_archived' : 'plugins.no_answer_no_archive.no_archive_removed'
          )
        )
      end

      format.json { head :no_content }
    end
  end
end

# eof
