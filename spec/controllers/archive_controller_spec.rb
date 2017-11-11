require 'rails_helper'

RSpec.describe ArchiveController, type: :controller do
  let(:thread) do
    create(:cf_thread,
           archived: true,
           created_at: Time.zone.parse('2016-02-01 00:00'),
           forum: create(:write_forum))
  end
  let(:older_thread) do
    create(:cf_thread,
           archived: true,
           created_at: Time.zone.parse('2016-01-01 00:00'),
           forum: thread.forum)
  end

  describe 'GET #years' do
    it 'assigns first year to @first_year' do
      thread # ensure creation
      get :years, params: { curr_forum: 'all' }
      expect(assigns(:first_year)).to eq thread.created_at.year
    end

    it 'assigns last year to @last_year' do
      get :years, params: { curr_forum: thread.forum.slug }
      expect(assigns(:last_year)).to eq thread.created_at.year
    end
  end

  describe 'GET #year' do
    it 'assigns valid months as @months' do
      older_thread # ensure creation
      get :year, params: { curr_forum: thread.forum.slug, year: thread.created_at.year }
      expect(assigns(:months)).to eq([older_thread.created_at.to_date, thread.created_at.to_date])
    end

    it 'assigns the year as @year' do
      older_thread # ensure creation
      get :year, params: { curr_forum: thread.forum.slug, year: thread.created_at.year }
      expect(assigns(:year).year).to eq(thread.created_at.year)
    end
  end

  describe 'GET #month' do
    before(:each) do
      create(:message, forum: thread.forum, thread: thread)
      create(:message, forum: older_thread.forum, thread: older_thread)
    end

    it 'assigns a list of threads to @threads' do
      get :month, params: { curr_forum: thread.forum.slug, year: '2016', month: 'feb' }
      expect(assigns(:threads)).to eq([thread])
    end

    it 'assigns the month as @month' do
      get :month, params: { curr_forum: thread.forum.slug, year: '2016', month: 'feb' }
      expect(assigns(:month)).to eq(Time.zone.parse('2016-02-01 00:00'))
    end

    it 'raises ActiveRecord::RecordNotFound on an invalid month' do
      expect do
        get :month, params: { curr_forum: thread.forum.slug, year: '2016', month: 'foo' }
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end
end

# eof
