module Api
  class DevsController < BaseController
    def list
      items, offset, max, total = paginate(Device.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| DevTranslatorBase.translator_for(d).to_flex(d) }
      }
    end

    def save
      dev_type = params[:devType]&.to_i
      klass = DevTranslatorBase.class_for_dev_type(dev_type)
      return render json: { error: "Invalid or missing devType" }, status: :unprocessable_entity unless klass

      translator = DevTranslatorBase::TRANSLATORS[klass.name]&.constantize || DevTranslatorBase
      attrs = translator.from_flex(params.to_unsafe_h)
      attrs[:sector] = default_sector

      device = klass.new(attrs)
      if device.save
        render json: { instance: translator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      device = find_by_id_or_uuid(Device, params[:id])
      return render json: { error: "Not found" }, status: :not_found unless device

      translator = DevTranslatorBase.translator_for(device)
      attrs = translator.from_flex(params.to_unsafe_h)
      if device.update(attrs)
        render json: { instance: translator.to_flex(device) }
      else
        render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete
      device = find_by_id_or_uuid(Device, params[:id])
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
