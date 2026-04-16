module Api
  class HolTypesController < BaseController
    def list
      items, offset, max, total = paginate(HolidayType.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ht| HolTypeTranslator.to_flex(ht) }
      }
    end

    def save
      attrs = HolTypeTranslator.from_flex(params.to_unsafe_h)
      ht = HolidayType.new(attrs)
      if ht.save
        render json: { instance: HolTypeTranslator.to_flex(ht) }
      else
        render json: { errors: ht.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ht = find_by_id_or_uuid(HolidayType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ht

      attrs = HolTypeTranslator.from_flex(params.to_unsafe_h)
      if ht.update(attrs)
        render json: { instance: HolTypeTranslator.to_flex(ht) }
      else
        render json: { errors: ht.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ht = find_by_id_or_uuid(HolidayType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ht

      ht.destroy
      render json: {}
    end
  end
end
