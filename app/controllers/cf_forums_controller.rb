# -*- encoding: utf-8 -*-

class CfForumsController < ApplicationController
  load_and_authorize_resource

  def index
    @forums = CfForum.order('name ASC').find(:all)
    results = CfThread.select('forum_id, COUNT(thread_id) AS cnt').group('forum_id')

    @counts = {}
    results.each do |r|
      @counts[r.forum_id] = r.cnt.to_i
    end
  end
end

# eof