module Api
  class HolCalsController < BaseController
    def list
      items, offset, max, total = paginate(HolidayCalendar.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |hc| HolCalTranslator.to_flex(hc) }
      }
    end

    def show
      hc = find_by_id_or_uuid(HolidayCalendar, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hc

      render json: { instance: HolCalTranslator.to_flex(hc) }
    end

    def save
      attrs = HolCalTranslator.from_flex(params.to_unsafe_h)
      hc = HolidayCalendar.new(attrs)
      if hc.save
        render json: { instance: HolCalTranslator.to_flex(hc) }
      else
        render json: { errors: hc.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      hc = find_by_id_or_uuid(HolidayCalendar, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hc

      attrs = HolCalTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(hc, attrs)
        render json: { instance: HolCalTranslator.to_flex(hc) }
      else
        render json: { errors: hc.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      hc = find_by_id_or_uuid(HolidayCalendar, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless hc

      hc.destroy
      render json: {}
    end
  end
end
