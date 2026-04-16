class DevTranslatorBase
  # Maps STI class names to the translator that handles each device type
  TRANSLATORS = {
    "IoController" => "ControllerTranslator",
    "Door" => "DoorTranslator",
    "CredReader" => "CredReaderTranslator",
    "Sensor" => "SensorTranslator",
    "Actuator" => "ActuatorTranslator",
    "NodeDev" => "NodeDevTranslator"
  }.freeze

  # Maps Flex devType integer to STI class
  DEV_TYPE_CLASSES = {
    0 => NodeDev,
    1 => IoController,
    2 => Sensor,
    3 => Actuator,
    4 => CredReader,
    5 => Door
  }.freeze

  def self.translator_for(device)
    name = TRANSLATORS[device.type]
    name ? name.constantize : self
  end

  def self.class_for_dev_type(dev_type)
    DEV_TYPE_CLASSES[dev_type]
  end

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
      externalId: device.external_id,
      enabled: device.enabled,
      address: device.address,
      logicalAddress: device.logical_address,
      macAddress: device.mac_address,
      port: device.port,
      speed: device.speed,
      devSubType: device.dev_sub_type,
      devMod: device.dev_mod,
      devPlatform: device.dev_platform,
      devUse: device.dev_use,
      timeZone: device.time_zone,
      ignoreDaylightSavings: device.ignore_daylight_savings,
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
    attrs[:external_id] = json["externalId"] if json.key?("externalId")
    attrs[:address] = json["address"] if json.key?("address")
    attrs[:logical_address] = json["logicalAddress"] if json.key?("logicalAddress")
    attrs[:mac_address] = json["macAddress"] if json.key?("macAddress")
    attrs[:port] = json["port"] if json.key?("port")
    attrs[:speed] = json["speed"] if json.key?("speed")
    attrs[:dev_sub_type] = json["devSubType"] if json.key?("devSubType")
    attrs[:dev_mod] = json["devMod"] if json.key?("devMod")
    attrs[:dev_platform] = json["devPlatform"] if json.key?("devPlatform")
    attrs[:dev_use] = json["devUse"] if json.key?("devUse")
    attrs[:time_zone] = json["timeZone"] if json.key?("timeZone")
    attrs[:ignore_daylight_savings] = json["ignoreDaylightSavings"] if json.key?("ignoreDaylightSavings")
    attrs[:dev_mod_config] = json["devModConfig"] if json.key?("devModConfig")

    # Legacy metadata extraction (brand/model/serialNumber nested under metadata)
    if json["metadata"].is_a?(Hash)
      attrs[:brand] = json["metadata"]["brand"] if json["metadata"].key?("brand")
      attrs[:model] = json["metadata"]["model"] if json["metadata"].key?("model")
      attrs[:serial_number] = json["metadata"]["serialNumber"] if json["metadata"].key?("serialNumber")
    end

    # Resolve parent ObjRefs
    if json.key?("physicalParent")
      attrs[:physical_parent_id] = resolve_device_ref(json["physicalParent"])
    end
    if json.key?("logicalParent")
      attrs[:logical_parent_id] = resolve_device_ref(json["logicalParent"])
    end

    attrs
  end

  def self.resolve_device_ref(ref)
    return nil unless ref.is_a?(Hash)

    if ref["unid"]
      ref["unid"]
    elsif ref["uuid"]
      Device.find_by(uuid: ref["uuid"])&.id
    end
  end

  private_class_method :resolve_device_ref
end
