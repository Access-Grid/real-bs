module Api
  class ActuatorsController < BaseController
    def list
      items, offset, max, total = paginate(Actuator.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| ActuatorTranslator.to_flex(d) }
      }
    end

    def save
      attrs = ActuatorTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = Actuator.new(attrs)
      if device.save
        render json: { instance: ActuatorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(Actuator, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      attrs = ActuatorTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(device, attrs)
        render json: { instance: ActuatorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(Actuator, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      device.destroy
      render json: {}
    end

    private

    def default_sector
      Sector.first || begin
        building = Building.first_or_create!(name: "Default")
        Sector.create!(name: "Default", building: building)
      end
    end
  end
end
