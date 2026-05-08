module Api
  class HolsController < BaseController
    def list
      items, offset, max, total = paginate(Holiday.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |h| HolTranslator.to_flex(h) }
      }
    end

    def show
      hol = find_by_id_or_uuid(Holiday, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hol

      render json: { instance: HolTranslator.to_flex(hol) }
    end

    def save
      attrs = HolTranslator.from_flex(params.to_unsafe_h)
      hol = Holiday.new(attrs)
      if hol.save
        HolTranslator.save_hol_types(hol, params.to_unsafe_h["holTypes"])
        render json: { instance: HolTranslator.to_flex(hol) }
      else
        render json: { errors: hol.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      hol = find_by_id_or_uuid(Holiday, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hol

      attrs = HolTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(hol, attrs)
        if params.to_unsafe_h.key?("holTypes")
          HolTranslator.save_hol_types(hol, params.to_unsafe_h["holTypes"])
        end
        render json: { instance: HolTranslator.to_flex(hol) }
      else
        render json: { errors: hol.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      hol = find_by_id_or_uuid(Holiday, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hol

      hol.destroy
      render json: {}
    end
  end
end
