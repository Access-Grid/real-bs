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

    def find_by_id_or_uuid(model_class, id)
      if id.to_s.match?(/\A\d+\z/)
        model_class.find_by(id: id)
      else
        model_class.find_by(uuid: id)
      end
    end

    def paginate(scope)
      offset = (params[:offset] || 0).to_i
      max = params[:max]&.to_i
      total = scope.count

      items = scope.offset(offset)
      items = items.limit(max) if max

      [ items, offset, max, total ]
    end
  end
end
