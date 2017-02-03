require 'rails_helper'

RSpec.describe CitesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/cites').to route_to('cites#index')
    end

    it 'routes to #show' do
      expect(get: '/cites/1').to route_to('cites#show', id: '1')
    end

    it 'routes to #new' do
      expect(get: '/cites/new').to route_to('cites#new')
    end

    it 'routes to #edit' do
      expect(get: '/cites/1/edit').to route_to('cites#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/cites').to route_to('cites#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/cites/1').to route_to('cites#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/cites/1').to route_to('cites#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/cites/1').to route_to('cites#destroy', id: '1')
    end
  end
end
