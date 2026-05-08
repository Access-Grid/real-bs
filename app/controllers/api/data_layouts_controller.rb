module Api
  class DataLayoutsController < BaseController
    def list
      items, offset, max, total = paginate(DataLayout.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |dl| BasicDataLayoutTranslator.to_flex(dl) }
      }
    end

    def show
      dl = find_by_id_or_uuid(DataLayout, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless dl

      render json: { instance: BasicDataLayoutTranslator.to_flex(dl) }
    end

    def save
      attrs = BasicDataLayoutTranslator.from_flex(params.to_unsafe_h)
      dl = DataLayout.new(attrs)
      if dl.save
        render json: { instance: BasicDataLayoutTranslator.to_flex(dl) }
      else
        render json: { errors: dl.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      dl = find_by_id_or_uuid(DataLayout, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless dl

      attrs = BasicDataLayoutTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(dl, attrs)
        render json: { instance: BasicDataLayoutTranslator.to_flex(dl) }
      else
        render json: { errors: dl.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      dl = find_by_id_or_uuid(DataLayout, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless dl

      dl.destroy
      render json: {}
    end
  end
end
