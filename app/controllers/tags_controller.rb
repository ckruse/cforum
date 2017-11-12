class TagsController < ApplicationController
  authorize_controller { authorize_forum(permission: :read?) }
  authorize_action(%i[new create]) { may?(Badge::CREATE_TAGS) }
  authorize_action(%i[edit update destroy merge do_merge]) { authorize_admin }

  # GET /collections
  # GET /collections.json
  def index
    if params[:s].present?
      clean_tag = params[:s].strip + '%'
      @tags = Tag
                .preload(:synonyms)
                .where('forum_id = ? AND (LOWER(tag_name) LIKE LOWER(?) OR tag_id IN (' \
                       '  SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) LIKE LOWER(?)))',
                       current_forum.forum_id, clean_tag, clean_tag)
                .order('tag_name ASC')
    else
      @tags = Tag.preload(:synonyms).order('tag_name ASC').where(forum_id: current_forum.forum_id)
    end

    respond_to do |format|
      format.html do
        @max_count = 0
        @min_count = -1

        @tags.each do |t|
          t.num_messages ||= 0

          @max_count = t.num_messages if t.num_messages > @max_count
          @min_count = t.num_messages if t.num_messages < @min_count || (@min_count == -1)
        end
      end
      format.json { render json: @tags, include: [:synonyms] }
    end
  end

  # just a post wrapper
  def suggestions
    expires_in 1.hour, public: true
    last_msg = Message
                 .where(forum_id: current_forum.forum_id)
                 .order(updated_at: :desc)
                 .first

    return if last_msg && !stale?(last_modified: last_msg.updated_at, public: true)

    @tags = Tag
              .where('forum_id = ? AND suggest = true', current_forum.forum_id)
              .order('num_messages DESC')
    @synonyms = TagSynonym
                  .joins(:tag)
                  .where('tag_synonyms.forum_id = ? AND tags.suggest = true', current_forum.forum_id)
                  .order('synonym ASC')

    retval = (@tags.map { |t| { tag: t.tag_name, num_msgs: t.num_messages } }) +
             (@synonyms.map { |s| { tag: s.synonym, num_msgs: 0 } })

    render json: retval
  end

  def autocomplete
    term = (params[:s] || params[:term]).to_s.strip

    @tags = Tag
              .preload(:synonyms)
              .where(forum_id: current_forum.forum_id,
                     suggest: true)

    if term.present?
      clean_tag = term.strip + '%'
      @tags = @tags
                .preload(:synonyms)
                .where('LOWER(tag_name) LIKE LOWER(?) OR tag_id IN (' \
                       '  SELECT tag_id FROM tag_synonyms WHERE LOWER(synonym) LIKE LOWER(?))',
                       clean_tag,
                       clean_tag)
    end

    @tags_list = []
    rx = nil
    rx = Regexp.new('^' + Regexp.escape(term.downcase), Regexp::IGNORECASE) if term.present?

    @tags.each do |t|
      @tags_list << t.tag_name if rx.blank? || rx.match(t.tag_name)

      t.synonyms.each do |s|
        @tags_list << s.synonym if rx.blank? || rx.match(s.synonym)
      end
    end

    render json: @tags_list.sort
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @limit = uconf('pagination').to_i
    @tag = Tag.preload(:synonyms).where('tags.forum_id = ? AND slug = ?',
                                        current_forum.forum_id, params[:id])
             .first!

    @tag.num_messages ||= 0

    @messages = Message.preload(:owner, tags: :synonyms, thread: :forum)
                  .joins('INNER JOIN messages_tags USING(message_id)')
                  .where('messages_tags.tag_id' => @tag.tag_id,
                         forum_id: current_forum.forum_id)
                  .order('messages.created_at DESC').page(params[:page]).per(@limit)

    @messages = @messages.where(deleted: false) unless @view_all

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag, include: [:synonyms] }
    end
  end

  def tag_params
    params.require(:tag).permit(:tag_name, :suggest)
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.forum_id = current_forum.forum_id

    @tag.slug = @tag.tag_name.parameterize if @tag.tag_name.present?

    if @tag.save
      audit(@tag, 'create')
      redirect_to tags_url(current_forum.slug), notice: t('tags.created')
    else
      render :new
    end
  end

  def edit
    @tag = Tag.where('tags.forum_id = ? AND slug = ?',
                     current_forum.forum_id, params[:id]).first!
  end

  def update
    @tag = Tag.where('tags.forum_id = ? AND slug = ?',
                     current_forum.forum_id, params[:id]).first!

    @tag.attributes = tag_params

    @tag.slug = @tag.tag_name.parameterize if @tag.tag_name.present?

    if @tag.save
      audit(@tag, 'update')
      redirect_to tags_url(current_forum.slug), notice: t('tags.updated')
    else
      render :edit
    end
  end

  def destroy
    @tag = Tag
             .where('tags.forum_id = ? AND slug = ?',
                    current_forum.forum_id, params[:id]).first!

    if @tag.messages.present?
      redirect_to tag_url(current_forum.slug, @tag), alert: t('tags.tag_has_messages')
      return
    end

    @tag.destroy
    audit(@tag, 'destroy')

    redirect_to tags_url(current_forum.slug), notice: t('tags.destroyed')
  end

  def merge
    @tag = Tag.where('tags.forum_id = ? AND slug = ?',
                     current_forum.forum_id, params[:id]).first!
    @tags = Tag
              .where(forum_id: current_forum.forum_id)
              .where('tag_id != ?', @tag.tag_id)
              .order('tag_name ASC')
  end

  def do_merge
    @tag = Tag.where('tags.forum_id = ? AND slug = ?',
                     current_forum.forum_id, params[:id]).first!
    @merge_tag = Tag.where('tags.forum_id = ? AND tag_id = ?',
                           current_forum.forum_id, params[:merge_tag]).first!

    Message.transaction do
      MessageTag.where(tag_id: @tag.tag_id)
        .update_all(tag_id: @merge_tag.tag_id)

      TagSynonym.where(tag_id: @tag.tag_id)
        .update_all(tag_id: @merge_tag.tag_id)

      @merge_tag.synonyms.create!(synonym: @tag.tag_name,
                                  forum_id: current_forum.forum_id)

      @tag.destroy

      audit(@merge_tag, 'merge')
      audit(@tag, 'destroy')
    end

    redirect_to tag_url(current_forum, @merge_tag), notice: t('tags.merged')
  end
end

# eof
