class Messages::NoAnswerController < ApplicationController
  authorize_controller { authorize_forum(permission: :moderator?) }

  def forbid_answer
    @thread, @message, @id = get_thread_w_post

    Message.transaction do
      @message.flag_with_subtree('no-answer-admin', 'yes')
      audit(@message, 'no-answer-admin-yes')
    end

    respond_to do |format|
      format.html do
        redirect_to(cf_return_url(@thread, @message, view_all: true),
                    notice: I18n.t('plugins.no_answer_no_archive.no_answered'))
      end

      format.json { head :no_content }
    end
  end

  def allow_answer
    @thread, @message, @id = get_thread_w_post

    Message.transaction do
      @message.flag_with_subtree('no-answer-admin', 'no')
      audit(@message, 'no-answer-admin-no')
    end

    respond_to do |format|
      format.html do
        redirect_to(cf_return_url(@thread, @message, view_all: true),
                    notice: I18n.t('plugins.no_answer_no_archive.no_answer_removed'))
      end

      format.json { head :no_content }
    end
  end
end

# eof
