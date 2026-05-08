module Api
  class SensorsController < BaseController
    def list
      items, offset, max, total = paginate(Sensor.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| SensorTranslator.to_flex(d) }
      }
    end

    def show
      device = find_by_id_or_uuid(Sensor, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      render json: { instance: SensorTranslator.to_flex(device) }
    end

    def save
      attrs = SensorTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = Sensor.new(attrs)
      if device.save
        render json: { instance: SensorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(Sensor, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      attrs = SensorTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(device, attrs)
        render json: { instance: SensorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(Sensor, params[:id])
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
