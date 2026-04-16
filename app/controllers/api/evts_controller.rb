module Api
  class EvtsController < BaseController
    def list
      scope = Event.all
      scope = apply_order(scope)
      items, offset, max, total = paginate(scope)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |e| EvtTranslator.to_flex(e) }
      }
    end

    def show
      evt = find_by_id_or_uuid(Event, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless evt

      render json: { instance: EvtTranslator.to_flex(evt) }
    end

    private

    def apply_order(scope)
      order = params[:order]
      if order == "asc"
        scope.order(hw_time: :asc)
      elsif order == "desc"
        scope.order(hw_time: :desc)
      else
        scope.order(hw_time: :desc)
      end
    end
  end
end
