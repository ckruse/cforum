require 'rails_helper'

RSpec.describe Admin::BadgeGroupsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/badge_groups').to route_to('admin/badge_groups#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/badge_groups/new').to route_to('admin/badge_groups#new')
    end

    it 'routes to #edit' do
      expect(get: '/admin/badge_groups/1/edit').to route_to('admin/badge_groups#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/badge_groups').to route_to('admin/badge_groups#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/badge_groups/1').to route_to('admin/badge_groups#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/badge_groups/1').to route_to('admin/badge_groups#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/badge_groups/1').to route_to('admin/badge_groups#destroy', id: '1')
    end
  end
end
