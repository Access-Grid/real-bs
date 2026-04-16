module Api
  class CredReadersController < BaseController
    def list
      items, offset, max, total = paginate(CredReader.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| CredReaderTranslator.to_flex(d) }
      }
    end

    def save
      attrs = CredReaderTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = CredReader.new(attrs)
      if device.save
        render json: { instance: CredReaderTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(CredReader, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      attrs = CredReaderTranslator.from_flex(params.to_unsafe_h)
      if device.update(attrs)
        render json: { instance: CredReaderTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(CredReader, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      device.destroy
      render json: {}
    end

    private

    def default_sector
      Sector.first || begin
        building = Building.first_or_create!(name: "Default")
        Sector.create!(name: "Default", building: building)
      end
    end
  end
end
