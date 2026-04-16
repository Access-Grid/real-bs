module Api
  class AuthenticationController < BaseController
    skip_before_action :authenticate!, only: :create

    def create
      user = User.find_by(username: params[:username])

      if user&.authenticate(params[:password])
        session = user.api_sessions.create!(
          expires_at: 24.hours.from_now,
          api_client_type: params[:apiClientType]
        )

        render json: {
          authenticated: true,
          sessionToken: session.session_token,
          softwareVersion: "0.1.0",
          softwareVersionTimestamp: "2026-04-16",
          timeZone: Time.zone.name,
          apiVersion: "1.1"
        }
      else
        render json: { authenticated: false }
      end
    end

    def terminate
      @current_session.destroy
      render json: {}
    end
  end
end
