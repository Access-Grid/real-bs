class DevTranslatorBase
  def self.obj_ref(record)
    return nil unless record
    ref = {
      unid: record.id,
      name: record.name,
      type: record.class.name
    }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.base_dev_fields(device)
    {
      devType: device.dev_type,
      unid: device.id,
      uuid: device.uuid,
      name: device.name,
      enabled: device.enabled,
      physicalParent: obj_ref(device.physical_parent),
      logicalParent: obj_ref(device.logical_parent),
      physicalChildren: device.physical_children.map { |c| obj_ref(c) },
      logicalChildren: device.logical_children.map { |c| obj_ref(c) }
    }
  end

  def self.base_from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:enabled] = json["enabled"] if json.key?("enabled")
    if json["metadata"].is_a?(Hash)
      attrs[:brand] = json["metadata"]["brand"] if json["metadata"].key?("brand")
      attrs[:model] = json["metadata"]["model"] if json["metadata"].key?("model")
      attrs[:serial_number] = json["metadata"]["serialNumber"] if json["metadata"].key?("serialNumber")
    end
    attrs
  end
end
