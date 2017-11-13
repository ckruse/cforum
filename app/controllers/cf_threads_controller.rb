require 'digest/sha1'

class CfThreadsController < ApplicationController
  authorize_action(%i[index show]) { authorize_forum(permission: :read?) }
  authorize_action(%i[new create]) { authorize_forum(permission: :write?) }
  authorize_action(%i[moving move sticky]) { authorize_forum(permission: :moderator?) }

  include TagsHelper
  include ThreadsHelper
  include MentionsHelper
  include ReferencesHelper
  include UserDataHelper
  include SuspiciousHelper
  include HighlightHelper
  include SearchHelper
  include InterestingHelper
  include SpamHelper
  include LinkTagsHelper
  include OpenCloseHelper
  include SubscriptionsHelper
  include NewMessageHelper

  def index
    index_threads

    ret = show_threads_functions(@threads)

    return if ret == :redirected

    respond_to do |format|
      format.html
      format.json { render json: @threads, include: { messages: { include: %i[owner tags] } } }
      format.rss
      format.atom
    end
  end

  def show
    @thread, @id = get_thread

    # don't show users threads he may not access via /all
    raise CForum::ForbiddenException unless @thread.forum.read?(current_user)

    show_threads_functions([@thread])

    respond_to do |format|
      format.html { render partial: 'thread', layout: false, locals: { thread: @thread } }
      format.rss
      format.atom
    end
  end

  def message_params
    params
      .require(:cf_thread)
      .require(:message)
      .permit(:subject, :content, :author, :email, :homepage, :problematic_site)
  end

  def new
    @thread = CfThread.new
    @thread.message = Message.new(params[:cf_thread].blank? ? {} : message_params)
    @tags = parse_tags

    @max_tags = conf('max_tags_per_message')

    set_user_data_vars(@thread.message)
  end

  def create
    invalid = false

    @forum = current_forum
    if @forum.blank?
      @forum = Forum
                 .where(forum_id: params[:cf_thread][:forum_id])
                 .where('forum_id IN (?)', Forum.visible_forums(current_user).select(:forum_id))
                 .first!
    end

    @thread  = CfThread.new
    @message = Message.new(message_params)
    @thread.message = @message
    @thread.slug = CfThread.gen_id(@thread)

    if @thread.slug.end_with?('/') && @thread.message.subject.present?
      flash.now[:error] = t('errors.could_not_generate_slug')
      invalid = true
    end

    @thread.forum_id = @forum.forum_id
    set_message_attibutes(@message, @thread)
    save_mentions(@message)
    @thread.latest_message = @message.created_at
    invalid = true unless message_author(@message)

    @tags    = parse_tags
    @preview = true if params[:preview]

    invalid = true unless validate_tags(@tags, @forum)
    if spam?(@message)
      invalid = true
      flash.now[:error] = t('global.spam_filter')
    end

    save_user_cookies(@message)

    saved = false
    if !invalid && !@preview
      CfThread.transaction do
        save_thread(@thread)
        @message.thread_id = @thread.thread_id
        raise ActiveRecord::Rollback unless @message.save

        save_tags(@forum, @message, @tags)

        @thread.messages << @message
        save_references(@message)
        audit(@thread, 'create')

        saved = true
      end
    end

    respond_to do |format|
      if !@preview && saved
        new_message_saved(@thread, @message, nil, @forum, 'thread')
        format.html { redirect_to message_url(@thread, @message), notice: I18n.t('threads.created') }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        # provoke a validation in case of missing tags
        @thread.message.valid? unless @preview
        @preview = true

        format.html { render action: 'new' }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def moving
    @id = CfThread.make_id(params)
    @thread = CfThread.includes(:forum).where(slug: @id).first!
    @thread.gen_tree
    @forums = Forum.order(name: :asc)

    return if current_user.admin

    @forums = Forum.where('forum_id IN ' \
                          '  (SELECT forum_id FROM forums_groups_permissions INNER JOIN groups_users USING(group_id) ' \
                          '   WHERE user_id = ? AND permission = ?)',
                          current_user.user_id,
                          ForumGroupPermission::MODERATE)
  end

  def move
    moving

    @move_to = Forum.find params[:move_to]
    @forum = @thread.forum
    raise CForum::ForbiddenException unless @forums.include?(@move_to)

    saved = false

    CfThread.transaction do
      @thread.forum_id = @move_to.forum_id
      @thread.save
      audit(@thread, 'move')

      @thread.messages.each do |m|
        m.forum_id = @move_to.forum_id
        m.save
        audit(m, 'move')
      end

      saved = true
    end

    respond_to do |format|
      if saved
        NotifyThreadMovedJob.perform_later(@thread.thread_id, @forum.forum_id, @move_to.forum_id)

        format.html { redirect_to message_url(@thread, @thread.message), notice: t('threads.moved') }
      else
        format.html { render :moving }
      end
    end
  end

  def sticky
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by!(slug: @id)

    @thread.sticky = !@thread.sticky

    if @thread.save
      type = @thread.sticky ? 'sticky' : 'unsticky'
      audit(@thread, type)
      redirect_to forum_url(current_forum), notice: I18n.t('threads.' + type)
    else
      redirect_to forum_url(current_forum), alert: I18n.t('threads.sticky_error')
    end
  end

  def redirect_to_page
    if params[:tid].blank?
      render html: IO.read(Rails.root + 'public/404.html').html_safe, status: 404
      return
    end

    if uconf('page_messages') == 'yes'
      threads, sticky_threads = index_threads(true, -1, -1, false, true)
      threads = threads.gsub(/SELECT.*?FROM/, 'SELECT threads.thread_id FROM')
      sticky_threads = sticky_threads.gsub(/SELECT.*?FROM/, 'SELECT COUNT(*) FROM').gsub(/ORDER BY.*/, '')

      threads = CfThread.connection.execute threads
      sticky_threads = CfThread.connection.execute sticky_threads

      tid = params[:tid].to_i
      pos = 0
      found = false
      prev = nil

      threads.each do |row|
        if row['thread_id'].to_i == tid
          found = true
          break
        end

        if prev.nil? || prev != row['thread_id']
          pos += 1
          prev = row['thread_id']
        end
      end

      unless found
        redirect_to forum_url(current_forum) + '#t' + params[:tid]
        return
      end

      paging = uconf('pagination').to_i
      paging -= sticky_threads[0]['count'].to_i
      page = pos / paging

      redirect_to forum_url(current_forum, p: page) + '#t' + params[:tid]
    else
      redirect_to forum_url(current_forum) + '#t' + params[:tid]
    end
  end

  def show_threads_functions(threads)
    check_threads_for_suspiciousness(threads)
    check_threads_for_highlighting(threads)
    mark_threads_interesting(threads)
    leave_out_invisible_for_threadlist(threads)
    thread_list_link_tags
    read_threadlist?(threads)
    open_close_threadlist(threads)
    mark_threads_subscribed(threads)
  end
end

# eof
