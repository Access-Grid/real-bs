module Api
  class DevStateRecordsController < BaseController
    def list
      items, offset, max, total = paginate(Device.all)
      render json: {
        offset: offset,
        max: max || items.size,
        count: total,
        instanceList: items.map { |d| dev_state_record(d) }
      }
    end

    private

    def dev_state_record(device)
      {
        unid: device.id,
        dev: DevTranslatorBase.obj_ref(device),
        devState: {
          devAspectStates: []
        }
      }
    end
  end
end
