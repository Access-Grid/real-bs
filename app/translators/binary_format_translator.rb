class BinaryFormatTranslator
  def self.to_flex(cf)
    {
      unid: cf.id,
      uuid: cf.uuid,
      version: cf.lock_version,
      tag: cf.tag,
      name: cf.name,
      dataFormatType: cf.data_format_type || 1,
      minBits: cf.min_bits,
      maxBits: cf.max_bits,
      supportReverseRead: cf.support_reverse_read || false,
      elements: cf.elements || []
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:lock_version] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:data_format_type] = json["dataFormatType"] if json.key?("dataFormatType")
    attrs[:min_bits] = json["minBits"] if json.key?("minBits")
    attrs[:max_bits] = json["maxBits"] if json.key?("maxBits")
    attrs[:support_reverse_read] = json["supportReverseRead"] if json.key?("supportReverseRead")
    attrs[:elements] = json["elements"] if json.key?("elements")
    attrs
  end
end
