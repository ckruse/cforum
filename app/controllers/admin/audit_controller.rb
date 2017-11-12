class Admin::AuditController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @objects = []
    @events = []
    @stop_date = DateTime.now
    @start_date = @stop_date - 24.hours

    if params[:start_date].present?
      @start_date = Time.zone.parse(params[:start_date][:year].to_s + '-' +
                                    params[:start_date][:month].to_s + '-' +
                                    params[:start_date][:day].to_s + ' 00:00:00')
    end

    if params[:stop_date].present?
      @stop_date = Time.zone.parse(params[:stop_date][:year].to_s + '-' +
                                   params[:stop_date][:month].to_s + '-' +
                                   params[:stop_date][:day].to_s + ' 23:59:59')
    end

    @audits = Auditing
                .preload(:user)
                .joins('LEFT JOIN users USING(user_id)')
                .where('auditing.created_at >= ?', @start_date)
                .where('auditing.created_at <= ?', @stop_date)
                .order(created_at: :desc)
                .page(params[:page])
                .per(conf('pagination').to_i)

    if params[:objects].present?
      @objects = params[:objects].map(&:strip)
      @audits = @audits.where(relation: @objects)
    end

    if params[:events].present?
      @events = params[:events].map(&:strip).select do |e|
        rel, = e.split('_', 2)
        @objects.include?(rel)
      end

      sql = []
      sql_params = []
      @events.each do |ev|
        sql << '(relation = ? AND act = ?)'
        act, rel = ev.split('_', 2)
        sql_params << act << rel
      end

      @audits = @audits.where(sql.join(' OR '), *sql_params)
    end

    return if params[:term].blank?

    @audits = @audits.where('UPPER(username) LIKE UPPER(?)', params[:term].strip + '%')
  end
end

# eof
