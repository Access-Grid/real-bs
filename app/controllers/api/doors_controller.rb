module Api
  class DoorsController < BaseController
    def list
      items, offset, max, total = paginate(Door.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| DoorTranslator.to_flex(d) }
      }
    end

    def save
      attrs = DoorTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = Door.new(attrs)
      if device.save
        render json: { instance: DoorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(Door, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      attrs = DoorTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(device, attrs)
        render json: { instance: DoorTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(Door, params[:id])
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
