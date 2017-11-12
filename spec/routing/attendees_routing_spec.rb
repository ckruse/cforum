require 'rails_helper'

RSpec.describe AttendeesController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/events/1/attendees/new').to route_to(controller: 'attendees',
                                                         action: 'new',
                                                         event_id: '1')
    end

    it 'routes to #create' do
      expect(post: '/events/1/attendees').to route_to(controller: 'attendees',
                                                      action: 'create',
                                                      event_id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/events/1/attendees/1').to route_to(controller: 'attendees',
                                                          action: 'destroy',
                                                          event_id: '1',
                                                          id: '1')
    end
  end
end
