class ImagesController < ApplicationController
  authorize_action(%i[index destroy]) { authorize_admin }

  def index
    @media = sort_query(%w[created_at orig_name owner_id], Medium)
               .page(params[:page])
               .per(conf('pagination').to_i)
  end

  def show
    @medium = Medium.where(filename: params[:id].to_s + '.' + params[:format].to_s).first!
    @size = case params[:size]
            when 'thumb' then :thumb
            when 'medium' then :medium
            else :orig
            end

    @size = :orig unless File.exist?(@medium.full_path(@size))

    expires_in 1.month, public: true

    return unless stale?(@medium, public: true)

    send_file(@medium.full_path(@size).to_s,
              type: @medium.content_type,
              filename: @medium.orig_name,
              disposition: :inline)
  end

  def create
    path, fname, error = nil
    @medium = Medium.new
    @medium.owner_id = current_user.user_id if current_user.present?

    if params[:file].content_type !~ %r{^image/}
      error = t('images.wrong_content_type')
    elsif params[:file].size > conf('max_image_filesize').to_f * 1024 * 1024
      error = t('images.image_too_big')
    else
      path, fname = Medium.gen_filename(params[:file].original_filename)
    end

    if fname.present?
      fd = File.open(path + fname, 'w:binary')
      fd.write(params[:file].read)
      fd.close

      @medium.filename = fname
      @medium.orig_name = params[:file].original_filename.gsub(%r{.*[\\/]}, '')
      @medium.content_type = params[:file].content_type
    end

    respond_to do |format|
      if fname.present? && @medium.save
        audit(@medium, 'create')
        ResizeImageJob.perform_later(@medium.medium_id)
        format.json { render json: { status: 'ok', path: @medium.filename } }
      else
        File.unlink(path + fname) if fname.present?
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
