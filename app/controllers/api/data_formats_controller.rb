module Api
  class DataFormatsController < BaseController
    def list
      items, offset, max, total = paginate(CredentialFormat.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |cf| BinaryFormatTranslator.to_flex(cf) }
      }
    end

    def save
      attrs = BinaryFormatTranslator.from_flex(params.to_unsafe_h)
      cf = CredentialFormat.new(attrs)
      if cf.save
        render json: { instance: BinaryFormatTranslator.to_flex(cf) }
      else
        render json: { errors: cf.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      cf = find_by_id_or_uuid(CredentialFormat, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cf

      attrs = BinaryFormatTranslator.from_flex(params.to_unsafe_h)
      if cf.update(attrs)
        render json: { instance: BinaryFormatTranslator.to_flex(cf) }
      else
        render json: { errors: cf.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      cf = find_by_id_or_uuid(CredentialFormat, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cf

      cf.destroy
      render json: {}
    end
  end
end
