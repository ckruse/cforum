require 'rails_helper'

RSpec.describe Admin::EventsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/events').to route_to('admin/events#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/events/new').to route_to('admin/events#new')
    end

    it 'routes to #edit' do
      expect(get: '/admin/events/1/edit').to route_to('admin/events#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/events').to route_to('admin/events#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/events/1').to route_to('admin/events#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/events/1').to route_to('admin/events#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/events/1').to route_to('admin/events#destroy', id: '1')
    end
  end
end

# eof
