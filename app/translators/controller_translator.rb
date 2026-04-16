class ControllerTranslator < DevTranslatorBase
  DEV_TYPE = 1 # DevType_IO_CONTROLLER

  def self.to_flex(access_controller)
    base_dev_fields(access_controller, DEV_TYPE).merge(
      physicalParent: obj_ref(access_controller.sector),
      logicalChildren: access_controller.entry_ways.map { |ew| obj_ref(ew) },
      controllerConfig: {}
    )
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
end
