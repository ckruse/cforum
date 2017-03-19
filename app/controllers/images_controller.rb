# -*- coding: utf-8 -*-

class ImagesController < ApplicationController
  authorize_action([:index, :destroy]) { authorize_admin }

  def index
    @media = sort_query(%w(created_at orig_name), Medium)
               .page(params[:page])
               .per(conf('pagination').to_i)
  end

  def show
    @medium = Medium.where(filename: params[:id].to_s + '.' + params[:format].to_s).first!

    expires_in 1.month, public: true

    if stale?(@medium, public: true)
      send_file Rails.root + 'public/uploads' + @medium.filename, type: @medium.content_type, filename: @medium.orig_name, disposition: :inline
    end
  end

  def create
    path, fname, error = nil
    @medium = Medium.new
    @medium.owner_id = current_user.user_id unless current_user.blank?

    if params[:file].content_type !~ /^image\//
      error = t('images.wrong_content_type')
    elsif params[:file].size > conf('max_image_filesize').to_f * 1024 * 1024
      error = t('images.image_too_big')
    else
      path, fname = Medium.gen_filename(params[:file].original_filename)
    end

    unless fname.blank?
      fd = File.open(path + fname, 'w:binary')
      fd.write(params[:file].read)
      fd.close
      @medium.filename = fname
      @medium.orig_name = params[:file].original_filename.gsub(/.*[\\\/]/, '')
      @medium.content_type = params[:file].content_type
    end

    respond_to do |format|
      if !fname.blank? && @medium.save
        audit(@medium, 'create')
        format.json { render json: { status: 'ok', path: @medium.filename } }
      else
        File.unlink(path + fname) unless fname.blank?
        format.json do
          render(json: { status: 'error', error: error ? [error] : @medium.errors },
                 status: :unprocessable_entity)
        end
      end
    end
  end

  def destroy
    @medium = Medium.where(filename: params[:id] + '.' + params[:format]).first!
    @medium.destroy
    audit(@medium, 'destroy')

    redirect_to images_url, notice: t('images.deleted_successfully')
  end
end

# eof
