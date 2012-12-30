# -*- coding: utf-8 -*-

class TagsController < ApplicationController
  # GET /collections
  # GET /collections.json
  def index
    unless params[:s].blank?
      @tags = CfTag.where("forum_id = ? AND UPPER(tag_name) LIKE UPPER(?)", current_forum.forum_id, params[:s].strip + '%').order('num_threads DESC').all
    else
      @tags = CfTag.order('tag_name ASC').find_all_by_forum_id current_forum.forum_id
    end

    respond_to do |format|
      format.html {
        @max_count = 0
        @min_count = -1

        @tags.each do |t|
          @max_count = t.num_threads if t.num_threads > @max_count
          @min_count = t.num_threads if t.num_threads < @min_count or @min_count == -1
        end
      }
      format.json { render json: @tags }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @limit = uconf('pagination', 100).to_i
    @tag = CfTag.where('tags.forum_id = ? AND slug = ?', current_forum.forum_id, params[:id]).first!

    @page = params[:p].to_i
    @page = 0 if @page < 0
    @page = (@tag.num_threads / @limit).ceil if @page > (@tag.num_threads / @limit).ceil

    offset = @page * @limit

    @threads = CfThread.preload(:forum, :messages => :owner).includes(:tags_threads).where('tags_threads.tag_id' => @tag.tag_id, deleted: false).order('threads.created_at DESC').limit(@limit).offset(offset).all

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag }
    end
  end

end

# eof
