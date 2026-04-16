class HolCalTranslator
  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: record.class.name }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(hc)
    {
      unid: hc.id,
      uuid: hc.uuid,
      name: hc.name
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs
  end
end
