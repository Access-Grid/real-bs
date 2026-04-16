module Api
  class ControllersController < BaseController
    def list
      items, offset, max, total = paginate(AccessController.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ac| ControllerTranslator.to_flex(ac) }
      }
    end

    def save
      attrs = ControllerTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      ac = AccessController.new(attrs)
      if ac.save
        render json: { instance: ControllerTranslator.to_flex(ac) }
      else
        render json: { errors: ac.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ac = find_by_id_or_uuid(AccessController, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ac

      attrs = ControllerTranslator.from_flex(params.to_unsafe_h)
      if ac.update(attrs)
        render json: { instance: ControllerTranslator.to_flex(ac) }
      else
        render json: { errors: ac.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ac = find_by_id_or_uuid(AccessController, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ac

      ac.destroy
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
