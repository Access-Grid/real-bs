module Api
  class BaseController < ActionController::API
    before_action :authenticate!

    private

    def authenticate!
      token = request.headers["sessionToken"]
      if token.blank?
        render json: { error: "Missing sessionToken header" }, status: :unauthorized
        return
      end

      @current_session = ApiSession.active.find_by(session_token: token)
      if @current_session.nil?
        render json: { error: "Invalid or expired sessionToken" }, status: :unauthorized
        return
      end

      @current_user = @current_session.user
    end

    def current_user
      @current_user
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
