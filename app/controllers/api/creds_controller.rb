module Api
  class CredsController < BaseController
    def list
      items, offset, max, total = paginate(Credential.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |c| CredTranslator.to_flex(c) }
      }
    end

    def save
      attrs = CredTranslator.from_flex(params.to_unsafe_h)
      cred = Credential.new(attrs)
      if cred.save
        render json: { instance: CredTranslator.to_flex(cred) }
      else
        render json: { errors: cred.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      cred = find_by_id_or_uuid(Credential, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cred

      attrs = CredTranslator.from_flex(params.to_unsafe_h)
      if cred.update(attrs)
        render json: { instance: CredTranslator.to_flex(cred) }
      else
        render json: { errors: cred.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      cred = find_by_id_or_uuid(Credential, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless cred

      cred.destroy
      render json: {}
    end
  end
end
