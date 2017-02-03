require 'rails_helper'

RSpec.describe TagsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/all/tags').to route_to('tags#index', curr_forum: 'all')
    end

    it 'routes to #new' do
      expect(get: '/all/tags/new').to route_to('tags#new', curr_forum: 'all')
    end

    it 'routes to #show' do
      expect(get: '/all/tags/foo').to route_to('tags#show', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #edit' do
      expect(get: '/all/tags/foo/edit').to route_to('tags#edit', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #create' do
      expect(post: '/all/tags').to route_to('tags#create', curr_forum: 'all')
    end

    it 'routes to #update via PUT' do
      expect(put: '/all/tags/foo').to route_to('tags#update', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/all/tags/foo').to route_to('tags#update', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #destroy' do
      expect(delete: '/all/tags/foo').to route_to('tags#destroy', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #merge' do
      expect(get: '/all/tags/foo/merge').to route_to('tags#merge', id: 'foo', curr_forum: 'all')
    end

    it 'routes to #do_merge' do
      expect(post: '/all/tags/foo/merge').to route_to('tags#do_merge', id: 'foo', curr_forum: 'all')
    end
  end
end
