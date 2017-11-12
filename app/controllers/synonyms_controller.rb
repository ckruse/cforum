class SynonymsController < ApplicationController
  authorize_controller { authorize_forum(permission: :read?) }
  authorize_action(%i[new create]) { may?(Badge::CREATE_TAG_SYNONYM) }
  authorize_action(%i[edit update destroy]) { authorize_admin }

  before_action :load_resource

  respond_to :html, :json

  def load_resource
    @tag = Tag.where(forum_id: current_forum.forum_id,
                     slug: params[:tag_id]).first!

    return if params[:id].blank?

    @synonym = TagSynonym.where(forum_id: current_forum.forum_id,
                                tag_id: @tag.tag_id,
                                tag_synonym_id: params[:id]).first!
  end

  def tag_synonym_params
    params.require(:tag_synonym).permit(:synonym)
  end

  def new
    @synonym = TagSynonym.new
    respond_with @synonym
  end

  def create
    @synonym = TagSynonym.new(tag_synonym_params)
    @synonym.synonym.downcase!
    @synonym.forum_id = current_forum.forum_id
    @synonym.tag_id = @tag.tag_id

    if @synonym.save
      audit(@synonym, 'create')
      redirect_to tag_url(current_forum.slug, @tag), notice: t('tags.synonyms.created')
    else
      render :new
    end
  end

  def edit
    respond_with @synonym
  end

  def update
    if @synonym.update_attributes(tag_synonym_params)
      audit(@synonym, 'update')
      redirect_to tag_url(current_forum.slug, @tag), notice: t('tags.synonyms.updated')
    else
      render :edit
    end
  end

  def destroy
    @synonym.destroy
    audit(@synonym, 'destroy')
    redirect_to tag_url(current_forum.slug, @tag), notice: t('tags.synonyms.destroyed')
  end
end

# eof
