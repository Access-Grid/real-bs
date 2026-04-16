module Api
  class BaseController < ActionController::API
    before_action :authenticate!

    private

    def authenticate!
      # Phase 1 will implement real token auth.
      # For now, allow all requests to enable API development.
    end

    def render_list_response(items, offset: 0, max: nil)
      render json: {
        offset: offset,
        max: max || items.size,
        count: items.size,
        instanceList: items
      }
    end
  end
end
