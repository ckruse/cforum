# -*- coding: utf-8 -*-

class TagsController < ApplicationController
  # GET /collections
  # GET /collections.json
  def index
    if not params[:s].blank?
      clean_tag = params[:s].strip + '%'
      @tags = CfTag.preload(:synonyms).where("forum_id = ? AND (LOWER(tag_name) LIKE LOWER(?) OR tag_id IN (SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) LIKE LOWER(?)))", current_forum.forum_id, clean_tag, clean_tag).order('num_messages DESC')
    elsif not params[:tags].blank?
      tags = params[:tags].split(',')
      @tags = CfTag.preload(:synonyms).where("forum_id = ? AND (LOWER(tag_name) IN (?) OR tag_id IN (SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) IN (?)))", current_forum.forum_id, tags, tags).order('num_messages DESC')
    else
      @tags = CfTag.preload(:synonyms).order('tag_name ASC').where(forum_id: current_forum.forum_id)
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

  def autocomplete
    if not params[:s].blank?
      clean_tag = params[:s].strip + '%'
      @tags = CfTag.preload(:synonyms).where("forum_id = ? AND (LOWER(tag_name) LIKE LOWER(?) OR tag_id IN (SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) LIKE LOWER(?)))", current_forum.forum_id, clean_tag, clean_tag)
    else
      @tags = CfTag.preload(:synonyms).find_all_by_forum_id current_forum.forum_id
    end

    @tags_list = {}
    @tags.each do |t|
      if params[:s].blank? or t.tag_name =~ Regexp.new('^' + params[:s].strip.downcase)
        @tags_list[t.tag_name] ||= 0
        @tags_list[t.tag_name] += t.num_messages
      end

      t.synonyms.each do |s|
        if params[:s].blank? or s.synonym =~ Regexp.new('^' + params[:s].strip.downcase)
          @tags_list[s.synonym] ||= 0
          @tags_list[s.synonym] += t.num_messages - 1
        end
      end
    end

    render json: @tags_list.keys.sort { |a,b| @tags_list[b] <=> @tags_list[a]}
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @limit = uconf('pagination', 100).to_i
    @tag = CfTag.preload(:synonyms).where('tags.forum_id = ? AND slug = ?',
                                          current_forum.forum_id, params[:id]).
      first!

    @tag.num_messages ||= 0

    @messages = CfMessage.preload(:owner, tags: :synonyms, thread: :forum).
      joins('INNER JOIN messages_tags USING(message_id)').
      where('messages_tags.tag_id' => @tag.tag_id,
            forum_id: current_forum.forum_id,
            deleted: false).
      order('messages.created_at DESC').page(params[:p]).per(@limit)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag, include: [:synonyms] }
    end
  end

end

# eof
