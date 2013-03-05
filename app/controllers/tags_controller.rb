# -*- coding: utf-8 -*-

class TagsController < ApplicationController
  # GET /collections
  # GET /collections.json
  def index
    unless params[:s].blank?
      clean_tag = params[:s].strip + '%'
      @tags = CfTag.preload(:synonyms).where("forum_id = ? AND (UPPER(tag_name) LIKE UPPER(?) OR tag_id IN (SELECT tag_id FROM tag_synonyms WHERE UPPER(synonym) LIKE UPPER(?)))", current_forum.forum_id, clean_tag, clean_tag).order('num_messages DESC').all
    else
      @tags = CfTag.preload(:synonyms).order('tag_name ASC').find_all_by_forum_id current_forum.forum_id
    end

    respond_to do |format|
      format.html {
        @max_count = 0
        @min_count = -1

        @tags.each do |t|
          t.num_messages ||= 0

          @max_count = t.num_messages if t.num_messages > @max_count
          @min_count = t.num_messages if t.num_messages < @min_count or @min_count == -1
        end
      }
      format.json { render json: @tags, include: [:synonyms] }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @limit = uconf('pagination', 100).to_i
    @tag = CfTag.preload(:synonyms).where('tags.forum_id = ? AND slug = ?', current_forum.forum_id, params[:id]).first!

    @tag.num_messages ||= 0

    @page = params[:p].to_i
    @page = 0 if @page < 0
    @page = (@tag.num_messages / @limit).ceil if @page > (@tag.num_messages / @limit).ceil

    offset = @page * @limit

    @messages = CfMessage.preload(:owner, :tags => :synonyms, :thread => :forum).joins('INNER JOIN messages_tags USING(message_id)').where('messages_tags.tag_id' => @tag.tag_id, forum_id: current_forum.forum_id, deleted: false).order('messages.created_at DESC').limit(@limit).offset(offset).all

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag, include: [:synonyms] }
    end
  end

end

# eof
