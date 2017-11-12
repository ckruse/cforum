module TagsHelper
  def save_tags(forum, message, tags)
    tag_objs = []

    # first check if all tags are present
    unless tags.empty?
      # tag_objs = Tag.where('forum_id = ? AND LOWER(tag_name) IN (?)', forum.forum_id, tags).all
      tag_objs = Tag
                   .preload(:synonyms)
                   .where('forum_id = ? AND (LOWER(tag_name) IN (?) OR tag_id IN ( ' \
                          '  SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) IN (?)))',
                          forum.forum_id, tags, tags)
                   .order('num_messages DESC')
                   .to_a

      tags.each do |t|
        tag_obj = tag_objs.find do |to|
          if to.tag_name.downcase == t
            true
          else
            to.synonyms.find { |syn| syn.synonym == t }
          end
        end

        next if tag_obj.present?

        # create a savepoint (rails implements savepoints as nested transactions)
        tag_obj = Tag.create(forum_id: forum.forum_id, tag_name: t)

        if tag_obj.tag_id.blank?
          flash[:error] = t('messages.tags_invalid')
          raise ActiveRecord::Rollback
        end

        tag_objs << tag_obj
      end

      # then create the message/tag connections
      tag_objs.each do |to|
        message.tags << to
      end
    end

    tag_objs
    # save_tags
  end

  def parse_tags
    tags = []

    if params[:tags].present?
      tags = params[:tags]
      tags = tags.values unless tags.is_a?(Array)
      tags = (tags.map { |s| s.strip.downcase }).uniq

    # non-js variant for conservative people
    elsif params[:tag_list].present?
      tags = (params[:tag_list].split(',').map { |s| s.strip.downcase }).uniq
    end

    tags
  end

  def invalid_tags(forum, tags, _user = current_user)
    may_create = may?(Badge::CREATE_TAGS)
    invalid = []

    tags.each do |t|
      tag = Tag.exists?(['tags.forum_id = ? AND (LOWER(tag_name) = ? OR ' \
                         '  tag_id IN (SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) = ? AND forum_id = ?))',
                         forum.forum_id, t, t,
                         forum.forum_id])
      invalid << t if tag.blank? && !may_create
    end

    invalid
  end

  def validate_tags(_tags, forum = current_forum)
    @max_tags = conf('max_tags_per_message').to_i
    if @tags.length > @max_tags
      flash.now[:error] = I18n.t('messages.too_many_tags', max_tags: @max_tags)
      return false
    end

    @min_tags = conf('min_tags_per_message').to_i
    if @tags.length < @min_tags
      flash.now[:error] = I18n.t('messages.not_enough_tags', count: @min_tags)
      return false
    end

    iv_tags = invalid_tags(forum, @tags)
    if iv_tags.present?
      flash.now[:error] = t('messages.invalid_tags', count: iv_tags.length, tags: iv_tags.join(', '))
      return false
    end

    true
  end
end

# eof
