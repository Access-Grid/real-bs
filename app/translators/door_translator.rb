class DoorTranslator < DevTranslatorBase
  DEV_TYPE = 5 # DevType_DOOR

  def self.to_flex(entry_way)
    base_dev_fields(entry_way, DEV_TYPE).merge(
      physicalParent: obj_ref(entry_way.sector),
      logicalParent: obj_ref(entry_way.access_controller),
      logicalChildren: (
        entry_way.readers.map { |r| obj_ref(r) } +
        entry_way.sensors.map { |s| obj_ref(s) }
      ),
      doorConfig: {}
    )
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs
  end
end
