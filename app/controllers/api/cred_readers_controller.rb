module Api
  class CredReadersController < BaseController
    def list
      items, offset, max, total = paginate(Reader.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |r| CredReaderTranslator.to_flex(r) }
      }
    end

    def save
      attrs = CredReaderTranslator.from_flex(params.to_unsafe_h)
      attrs[:access_controller] = default_access_controller
      attrs[:entry_way] = default_entry_way

      reader = Reader.new(attrs)
      if reader.save
        render json: { instance: CredReaderTranslator.to_flex(reader) }
      else
        render json: { errors: reader.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      reader = find_by_id_or_uuid(Reader, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless reader

      attrs = CredReaderTranslator.from_flex(params.to_unsafe_h)
      if reader.update(attrs)
        render json: { instance: CredReaderTranslator.to_flex(reader) }
      else
        render json: { errors: reader.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      reader = find_by_id_or_uuid(Reader, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless reader

      reader.destroy
      render json: {}
    end

    private

    def default_sector
      Sector.first || begin
        building = Building.first_or_create!(name: "Default")
        Sector.create!(name: "Default", building: building)
      end
    end

    def default_access_controller
      AccessController.first || AccessController.create!(name: "Default", sector: default_sector)
    end

    def default_entry_way
      EntryWay.first || EntryWay.create!(name: "Default", sector: default_sector, access_controller: default_access_controller)
    end
  end
end
