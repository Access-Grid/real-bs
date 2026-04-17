module Api
  class CredHoldersController < BaseController
    def list
      items, offset, max, total = paginate(Person.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |p| CredHolderTranslator.to_flex(p) }
      }
    end

    def show
      person = find_by_id_or_uuid(Person, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless person

      render json: { instance: CredHolderTranslator.to_flex(person) }
    end

    def save
      attrs = CredHolderTranslator.from_flex(params.to_unsafe_h)
      person = Person.new(attrs)
      if person.save
        render json: { instance: CredHolderTranslator.to_flex(person) }
      else
        render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      person = find_by_id_or_uuid(Person, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless person

      attrs = CredHolderTranslator.from_flex(params.to_unsafe_h)
      if update_with_lock(person, attrs)
        render json: { instance: CredHolderTranslator.to_flex(person) }
      else
        render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      person = find_by_id_or_uuid(Person, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless person

      person.destroy
      render json: {}
    end
  end
end
