module Api
  class HealthController < BaseController
    skip_before_action :authenticate!

    def show
      render json: { status: "ok" }
    end
  end
end
