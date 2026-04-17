module Api
  class EncryptionKeysController < BaseController
    def list
      items, offset, max, total = paginate(EncryptionKey.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |ek| EncryptionKeyTranslator.to_flex(ek) }
      }
    end

    def save
      attrs = EncryptionKeyTranslator.from_flex(params.to_unsafe_h)
      ek = EncryptionKey.new(attrs)
      if ek.save
        render json: { instance: EncryptionKeyTranslator.to_flex(ek) }
      else
        render json: { errors: ek.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ek = find_by_id_or_uuid(EncryptionKey, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ek

      attrs = EncryptionKeyTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(ek, attrs)
        render json: { instance: EncryptionKeyTranslator.to_flex(ek) }
      else
        render json: { errors: ek.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      ek = find_by_id_or_uuid(EncryptionKey, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless ek

      ek.destroy
      render json: {}
    end
  end
end
