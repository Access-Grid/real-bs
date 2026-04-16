module Api
  class DoorsController < BaseController
    def list
      items, offset, max, total = paginate(EntryWay.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ew| DoorTranslator.to_flex(ew) }
      }
    end

    def save
      attrs = DoorTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector
      attrs[:access_controller] = default_access_controller

      ew = EntryWay.new(attrs)
      if ew.save
        render json: { instance: DoorTranslator.to_flex(ew) }
      else
        render json: { errors: ew.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ew = find_by_id_or_uuid(EntryWay, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ew

      attrs = DoorTranslator.from_flex(params.to_unsafe_h)
      if ew.update(attrs)
        render json: { instance: DoorTranslator.to_flex(ew) }
      else
        render json: { errors: ew.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ew = find_by_id_or_uuid(EntryWay, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ew

      ew.destroy
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
  end
end
