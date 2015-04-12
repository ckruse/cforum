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

  authorize_controller { authorize_forum(permission: :moderator?) }

  def no_answer
    @thread, @message, @id = get_thread_w_post

    retvals = notification_center.notify(@message.flags['no-answer-admin'] == 'yes' ? NO_ANSWER_REMOVING : NO_ANSWER, @thread, @message)

    unless retvals.include?(false)
      CfMessage.transaction do
        if @message.flags['no-answer-admin'] == 'yes'
          @message.flag_with_subtree('no-answer-admin', 'no')
        else
          @message.flag_with_subtree('no-answer-admin', 'yes')
        end
      end

      notification_center.notify(@message.flags['no-answer-admin'] == 'yes' ? NO_ANSWERED : NO_ANSWER_REMOVED, @thread, @message)
    end

    respond_to do |format|
      format.html do
        redirect_to(
          cf_return_url(@thread, @message, view_all: true),
          notice: I18n.t(@message.flags['no-answer-admin'] == 'yes' ?
                           'plugins.no_answer_no_archive.no_answered' :
                           'plugins.no_answer_no_archive.no_answer_removed'))
      end

      format.json { head :no_content }
    end
  end

  def no_archive
    @thread, @id = get_thread

    retvals = notification_center.notify(@thread.flags['no-archive'] == 'yes' ? NO_ARCHIVE_REMOVING : NO_ARCHIVE, @thread)

    unless retvals.include?(false)
      CfMessage.transaction do
        @thread.flags_will_change!

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
        redirect_to(cf_return_url(@thread, nil, view_all: true),
                    notice: I18n.t(@thread.flags['no-archive'] == 'yes' ?
                                     'plugins.no_answer_no_archive.no_archived' :
                                     'plugins.no_answer_no_archive.no_archive_removed'))
      end

      format.json { head :no_content }
    end
  end
end

# eof
