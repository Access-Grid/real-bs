module Api
  class SensorsController < BaseController
    def list
      items, offset, max, total = paginate(Sensor.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |s| SensorTranslator.to_flex(s) }
      }
    end

    def save
      attrs = SensorTranslator.from_flex(params.to_unsafe_h)
      attrs[:access_controller] = default_access_controller
      attrs[:entry_way] = default_entry_way

      sensor = Sensor.new(attrs)
      if sensor.save
        render json: { instance: SensorTranslator.to_flex(sensor) }
      else
        render json: { errors: sensor.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      sensor = find_by_id_or_uuid(Sensor, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless sensor

      attrs = SensorTranslator.from_flex(params.to_unsafe_h)
      if sensor.update(attrs)
        render json: { instance: SensorTranslator.to_flex(sensor) }
      else
        render json: { errors: sensor.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      sensor = find_by_id_or_uuid(Sensor, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless sensor

      sensor.destroy
      render json: {}
    end

    private

    def default_sector
      Sector.first || begin
        building = Building.first_or_create!(name: "Default")
        Sector.create!(name: "Default", building: building)
      end
    end

    def default_access_controller
      AccessController.first || AccessController.create!(name: "Default", sector: default_sector)
    end

    def default_entry_way
      EntryWay.first || EntryWay.create!(name: "Default", sector: default_sector, access_controller: default_access_controller)
    end
  end
end
