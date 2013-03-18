# -*- coding: utf-8 -*-

module ApplicationHelper
  include CForum::Tools
  include RightsHelper

  def current_forum
    unless params[:curr_forum].blank?
      @_current_forum = CfForum.find_by_slug(params[:curr_forum]) if !@_current_forum || @_current_forum.slug != params[:curr_forum]
      raise CForum::NotFoundException.new unless @_current_forum # TODO: error description
      return @_current_forum
    end

    @_current_forum = nil
  end
end

# eof
