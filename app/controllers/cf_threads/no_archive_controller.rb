class CfThreads::NoArchiveController < ApplicationController
  authorize_controller { authorize_forum(permission: :moderator?) }

  def no_archive
    @thread, @id = get_thread

    Message.transaction do
      @thread.flags_will_change!
      @thread.flags['no-archive'] = 'yes'

      audit(@thread, 'no-archive-yes')

      @thread.save
    end

    respond_to do |format|
      format.html do
        redirect_to(cf_return_url(@thread, nil, view_all: true),
                    notice: I18n.t('plugins.no_answer_no_archive.no_archived'))
      end

      format.json { head :no_content }
    end
  end

  def archive
    @thread, @id = get_thread

    Message.transaction do
      @thread.flags_will_change!
      @thread.flags.delete 'no-archive'

      audit(@thread, 'no-archive-no')

      @thread.save
    end

    respond_to do |format|
      format.html do
        redirect_to(cf_return_url(@thread, nil, view_all: true),
                    notice: I18n.t('plugins.no_answer_no_archive.no_archive_removed'))
      end

      format.json { head :no_content }
    end
  end
end

# eof
