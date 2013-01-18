# -*- coding: utf-8 -*-

module TagsHelper

  def save_tags(message, tags)
    tag_objs = []

    # first check if all tags are present
    unless tags.empty?
      tag_objs = CfTag.where('forum_id = ? AND LOWER(tag_name) IN (?)', current_forum.forum_id, tags).all
      tags.each do |t|
        tag_obj = tag_objs.find {|to| to.tag_name.downcase == t}

        if tag_obj.blank?
          # create a savepoint (rails implements savepoints as nested transactions)
          tag_obj = CfTag.create(forum_id: current_forum.forum_id, tag_name: t)

          if tag_obj.tag_id.blank?
            saved = false
            flash[:error] = t('messages.tag_invalid')
            raise ActiveRecord::Rollback.new
          end

          tag_objs << tag_obj
        end
      end

      # then create the message/tag connections
      tag_objs.each do |to|
        CfMessageTag.create!(tag_id: to.tag_id, message_id: message.message_id)
      end
    end

    message.tags = tag_objs
    tag_objs
  end # save_tags

  def parse_tags
    tags = []

    if not params[:tags].blank?
      tags = (params[:tags].map {|s| s.strip.downcase}).uniq
    # non-js variant for conservative people
    elsif not params[:tag_list].blank?
      tags = (params[:tag_list].split(',').map {|s| s.strip.downcase}).uniq
    end

    tags
  end

end

# eof