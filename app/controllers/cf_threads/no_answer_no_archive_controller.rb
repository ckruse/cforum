# -*- coding: utf-8 -*-

class CfThreads::NoAnswerNoArchiveController < ApplicationController
  authorize_controller { authorize_forum(permission: :moderator?) }

  def no_answer
    @thread, @message, @id = get_thread_w_post

    Message.transaction do
      if @message.flags['no-answer-admin'] == 'yes'
        @message.flag_with_subtree('no-answer-admin', 'no')
        audit(@message, 'no-answer-admin-no')
      else
        @message.flag_with_subtree('no-answer-admin', 'yes')
        audit(@message, 'no-answer-admin-yes')
      end
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

    Message.transaction do
      @thread.flags_will_change!

      if @thread.flags['no-archive'] == 'yes'
        @thread.flags.delete 'no-archive'
        audit(@thread, 'no-archive-no')
      else
        @thread.flags['no-archive'] = 'yes'
        audit(@thread, 'no-archive-yes')
      end

      @thread.save
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
