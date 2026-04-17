module Api
  class DoorAccessPrivsController < BaseController
    def list
      items, offset, max, total = paginate(AccessRuleSet.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ars| DoorAccessPrivTranslator.to_flex(ars) }
      }
    end

    def save
      attrs = DoorAccessPrivTranslator.from_flex(params.to_unsafe_h)
      ars = AccessRuleSet.new(attrs)
      if ars.save
        DoorAccessPrivTranslator.save_elements(ars, params.to_unsafe_h["elements"])
        render json: { instance: DoorAccessPrivTranslator.to_flex(ars) }
      else
        render json: { errors: ars.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ars = find_by_id_or_uuid(AccessRuleSet, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ars

      attrs = DoorAccessPrivTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(ars, attrs)
        if params.to_unsafe_h.key?("elements")
          DoorAccessPrivTranslator.save_elements(ars, params.to_unsafe_h["elements"])
        end
        render json: { instance: DoorAccessPrivTranslator.to_flex(ars) }
      else
        render json: { errors: ars.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ars = find_by_id_or_uuid(AccessRuleSet, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ars

      ars.destroy
      render json: {}
    end
  end
end
