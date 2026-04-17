class HolTypeTranslator
  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: FlexTypeNames.for(record) }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(ht)
    {
      unid: ht.id,
      uuid: ht.uuid,
      version: ht.lock_version,
      tag: ht.tag,
      externalId: ht.external_id,
      name: ht.name
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:lock_version] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:external_id] = json["externalId"] if json.key?("externalId")
    attrs
  end
end
