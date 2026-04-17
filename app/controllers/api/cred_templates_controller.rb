module Api
  class CredTemplatesController < BaseController
    def list
      items, offset, max, total = paginate(CredentialType.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ct| CredTemplateTranslator.to_flex(ct) }
      }
    end

    def save
      attrs = CredTemplateTranslator.from_flex(params.to_unsafe_h)
      ct = CredentialType.new(attrs)
      if ct.save
        render json: { instance: CredTemplateTranslator.to_flex(ct) }
      else
        render json: { errors: ct.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ct = find_by_id_or_uuid(CredentialType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ct

      attrs = CredTemplateTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(ct, attrs)
        render json: { instance: CredTemplateTranslator.to_flex(ct) }
      else
        render json: { errors: ct.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ct = find_by_id_or_uuid(CredentialType, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ct

      ct.destroy
      render json: {}
    end
  end
end
