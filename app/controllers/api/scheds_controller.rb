module Api
  class SchedsController < BaseController
    def list
      items, offset, max, total = paginate(Schedule.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |s| SchedTranslator.to_flex(s) }
      }
    end

    def save
      attrs = SchedTranslator.from_flex(params.to_unsafe_h)
      schedule = Schedule.new(attrs)
      if schedule.save
        SchedTranslator.save_elements(schedule, params.to_unsafe_h["elements"])
        render json: { instance: SchedTranslator.to_flex(schedule) }
      else
        render json: { errors: schedule.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      schedule = find_by_id_or_uuid(Schedule, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless schedule

      attrs = SchedTranslator.from_flex(params.to_unsafe_h)
      if schedule.update(attrs)
        if params.to_unsafe_h.key?("elements")
          SchedTranslator.save_elements(schedule, params.to_unsafe_h["elements"])
        end
        render json: { instance: SchedTranslator.to_flex(schedule) }
      else
        render json: { errors: schedule.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      schedule = find_by_id_or_uuid(Schedule, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless schedule

      schedule.destroy
      render json: {}
    end
  end
end
