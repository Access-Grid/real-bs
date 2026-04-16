class SensorTranslator < DevTranslatorBase
  DEV_TYPE = 2 # DevType_SENSOR

  def self.to_flex(sensor)
    base_dev_fields(sensor, DEV_TYPE).merge(
      logicalParent: obj_ref(sensor.entry_way),
      physicalParent: obj_ref(sensor.access_controller),
      sensorConfig: {}
    )
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    if json["metadata"].is_a?(Hash)
      attrs[:brand] = json["metadata"]["brand"] if json["metadata"].key?("brand")
      attrs[:model] = json["metadata"]["model"] if json["metadata"].key?("model")
      attrs[:serial_number] = json["metadata"]["serialNumber"] if json["metadata"].key?("serialNumber")
    end
    attrs
  end
end
