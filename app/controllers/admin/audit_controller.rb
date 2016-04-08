# -*- coding: utf-8 -*-

class Admin::AuditController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @objects = []
    @events = []
    @stop_date = DateTime.now
    @start_date = @stop_date - 24.hours

    unless params[:start_date].blank?
      @start_date = Time.zone.parse(params[:start_date][:year].to_s + '-' +
                                    params[:start_date][:month].to_s + '-' +
                                    params[:start_date][:day].to_s + ' 00:00:00')
    end

    unless params[:stop_date].blank?
      @stop_date = Time.zone.parse(params[:stop_date][:year].to_s + '-' +
                                   params[:stop_date][:month].to_s + '-' +
                                   params[:stop_date][:day].to_s + ' 23:59:59')
    end

    @audits = Auditing.
              preload(:user).
              joins('LEFT JOIN users USING(user_id)').
              where('auditing.created_at >= ?', @start_date).
              where('auditing.created_at <= ?', @stop_date).
              order(created_at: :desc).
              page(params[:page]).
              per(conf('pagination').to_i)

    unless params[:objects].blank?
      @objects = params[:objects].map { |o| o.strip }
      @audits = @audits.where(relation: @objects)
    end

    unless params[:events].blank?
      @events = (params[:events].map { |e| e.strip }).select { |e|
        rel, _ = e.split('_', 2)
        @objects.include?(rel)
      }

      sql = []
      sql_params = []
      @events.each do |ev|
        sql << '(relation = ? AND act = ?)'
        act, rel = ev.split('_', 2)
        sql_params << act << rel
      end

      @audits = @audits.where(sql.join(' OR '), *sql_params)
    end

    unless params[:term].blank?
      @audits = @audits.where('UPPER(username) LIKE UPPER(?)', params[:term].strip + '%')
    end

  end

end

# eof
