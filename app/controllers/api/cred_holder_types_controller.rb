module Api
  class CredHolderTypesController < BaseController
    def list
      items, offset, max, total = paginate(CredHolderType.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |cht| CredHolderTypeTranslator.to_flex(cht) }
      }
    end

    def show
      cht = find_by_id_or_uuid(CredHolderType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cht

      render json: { instance: CredHolderTypeTranslator.to_flex(cht) }
    end

    def save
      attrs = CredHolderTypeTranslator.from_flex(params.to_unsafe_h)
      cht = CredHolderType.new(attrs)
      if cht.save
        render json: { instance: CredHolderTypeTranslator.to_flex(cht) }
      else
        render json: { errors: cht.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      cht = find_by_id_or_uuid(CredHolderType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cht

      attrs = CredHolderTypeTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(cht, attrs)
        render json: { instance: CredHolderTypeTranslator.to_flex(cht) }
      else
        render json: { errors: cht.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      cht = find_by_id_or_uuid(CredHolderType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cht

      cht.destroy
      render json: {}
    end
  end
end
