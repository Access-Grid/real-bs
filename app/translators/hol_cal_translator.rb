class HolCalTranslator
  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: FlexTypeNames.for(record) }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(hc)
    {
      unid: hc.id,
      uuid: hc.uuid,
      version: hc.version_counter || 0,
      tag: hc.tag,
      name: hc.name
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:version_counter] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:name] = json["name"] if json.key?("name")
    attrs
  end
end
