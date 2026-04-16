module Api
  class DevActionsController < BaseController
    def door_mode_change
      door = resolve_device
      return render json: { error: "Device not found" }, status: :not_found unless door

      render json: {}
    end

    def door_momentary_unlock
      door = resolve_device
      return render json: { error: "Device not found" }, status: :not_found unless door

      render json: {}
    end

    private

    def resolve_device
      if params[:unid]
        Device.find_by(id: params[:unid])
      elsif params[:uuid]
        Device.find_by(uuid: params[:uuid])
      end
    end
  end
end
