class Messages::SplitThreadController < ApplicationController
  authorize_controller { authorize_forum(permission: :moderator?) }

  include TagsHelper
  include ThreadsHelper
  include SearchHelper
  include ReferencesHelper
  include SubscriptionsHelper

  def edit
    @thread, @message, @id = get_thread_w_post
    @tags = @message.tags.map(&:tag_name)
    @max_tags = conf('max_tags_per_message')
  end

  def update
    @old_thread, @message, @id = get_thread_w_post

    @forum = Forum
               .where(forum_id: params[:message][:forum_id])
               .where('forum_id IN (?)', Forum.visible_forums(current_user).select(:forum_id))
               .first!

    @message.subject = params[:message][:subject]

    @thread = CfThread.new(forum_id: @forum.forum_id)
    @thread.message = @message
    @thread.slug = CfThread.gen_id(@thread)
    @thread.latest_message = find_youngest(@message)

    @tags = parse_tags
    invalid = !validate_tags(@tags, @forum)

    saved = false
    unless invalid
      CfThread.transaction do
        save_thread(@thread)

        @message.thread_id = @thread.thread_id
        @message.parent_id = nil
        @message.forum_id  = @thread.forum_id
        @message.editor_id = current_user.user_id
        @message.edit_author = current_user.username

        Redirection.create!(path: message_path_wo_anchor(@old_thread, @message),
                            destination: message_path_wo_anchor(@thread, @message),
                            http_status: 301,
                            comment: t('messages.thread_split_redirection'))

        raise ActiveRecord::Rollback unless @message.save

        @message.tags.delete_all
        raise ActiveRecord::Rollback unless save_tags(@forum, @message, @tags)
        audit(@message, 'retag')

        @message.all_answers do |msg|
          msg.thread_id = @thread.thread_id
          msg.forum_id = @thread.forum_id
          raise ActiveRecord::Rollback unless msg.save

          Redirection.create!(path: message_path_wo_anchor(@old_thread, msg),
                              destination: message_path_wo_anchor(@thread, msg),
                              http_status: 301,
                              comment: t('messages.thread_split_redirection'))

          if params[:retag_answers] == '1'
            msg.tags.delete_all
            raise ActiveRecord::Rollback unless save_tags(@forum, msg, @tags)
            audit(msg, 'retag')
          end
        end

        search_index_message(@thread, @message)
        save_references(@message)
        audit(@thread, 'create')

        @old_thread.reload
        if @old_thread.messages.blank?
          @old_thread.destroy
        else
          @old_thread.latest_message = find_youngest_flat(@thread.messages)
          @old_thread.save!
        end

        saved = true
      end
    end

    if saved
      NotifyNewMessageJob.perform_later(@thread.thread_id, @message.message_id, 'thread')
      autosubscribe_message(@thread, nil, @message)

      redirect_to message_url(@thread, @message), notice: I18n.t('messages.thread_split')
    else
      render :edit
    end
  end

  def find_youngest(root_msg)
    youngest = root_msg
    root_msg.all_answers do |msg|
      youngest = msg if youngest.created_at < msg.created_at
    end

    youngest.created_at
  end

  def find_youngest_flat(messages)
    youngest = nil
    messages.each do |msg|
      youngest = msg if youngest.blank? || youngest.created_at < msg.created_at
    end

    youngest.created_at
  end
end

# eof
