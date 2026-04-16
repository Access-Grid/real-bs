class ControllerTranslator
  DEV_TYPE = 1 # DevType_IO_CONTROLLER

  def self.to_flex(access_controller)
    {
      devType: DEV_TYPE,
      unid: access_controller.id,
      uuid: access_controller.uuid,
      name: access_controller.name,
      enabled: true,
      physicalParent: obj_ref(access_controller.sector),
      logicalChildren: access_controller.entry_ways.map { |ew| obj_ref(ew) },
      controllerConfig: {}
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    if json["metadata"].is_a?(Hash)
      attrs[:brand] = json["metadata"]["brand"] if json["metadata"].key?("brand")
      attrs[:model] = json["metadata"]["model"] if json["metadata"].key?("model")
    end
    attrs
  end

  def self.obj_ref(record)
    return nil unless record
    {
      unid: record.id,
      name: record.name,
      type: record.class.name
    }
  end
end
