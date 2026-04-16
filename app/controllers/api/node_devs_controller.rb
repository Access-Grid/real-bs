module Api
  class NodeDevsController < BaseController
    def list
      items, offset, max, total = paginate(NodeDev.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| NodeDevTranslator.to_flex(d) }
      }
    end

    def save
      attrs = NodeDevTranslator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = NodeDev.new(attrs)
      if device.save
        render json: { instance: NodeDevTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(NodeDev, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      attrs = NodeDevTranslator.from_flex(params.to_unsafe_h)
      if device.update(attrs)
        render json: { instance: NodeDevTranslator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(NodeDev, params[:id])
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
