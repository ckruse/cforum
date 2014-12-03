# -*- coding: utf-8 -*-

class SynonymsController < ApplicationController
  authorize_controller { authorize_forum(permission: :read?) }
  authorize_action([:new, :create]) { may?(RightsHelper::CREATE_TAG_SYNONYM) }
  authorize_action([:edit, :update, :destroy]) { authorize_admin }

  before_filter :load_resource

  respond_to :html, :json

  def load_resource
    @tag = CfTag.where(forum_id: current_forum.forum_id,
                       slug: params[:tag_id]).first!

    if params[:id]
      @synonym = CfTagSynonym.where(forum_id: current_forum.forum_id,
                                    tag_id: @tag.tag_id,
                                    tag_synonym_id: params[:id]).first!
    end
  end

  def tag_synonym_params
    params.require(:cf_tag_synonym).permit(:synonym)
  end

  def new
    @synonym = CfTagSynonym.new
    respond_with @synonym
  end

  def create
    @synonym = CfTagSynonym.new(tag_synonym_params)
    @synonym.forum_id = current_forum.forum_id
    @synonym.tag_id = @tag.tag_id

    if @synonym.save
      redirect_to tag_url(current_forum.slug, @tag), notice: t("tags.synonym_created")
    else
      render :new
    end
  end

  def edit
    respond_with @synonym
  end

  def update
    if @synonym.update_attributes(tag_synonym_params)
      redirect_to tag_url(current_forum.slug, @tag), notice: t("tags.synonym_updated")
    else
      render :edit
    end
  end

  def destroy
    @synonym.destroy
    redirect_to tag_url(current_forum.slug, @tag), notice: t("tags.synonym_destroyed")
  end
end

# eof
