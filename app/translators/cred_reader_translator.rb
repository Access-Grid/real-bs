class CredReaderTranslator < DevTranslatorBase
  DEV_TYPE = 4 # DevType_CRED_READER

  def self.to_flex(reader)
    base_dev_fields(reader, DEV_TYPE).merge(
      logicalParent: obj_ref(reader.entry_way),
      physicalParent: obj_ref(reader.access_controller),
      credReaderConfig: {}
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
