class BasicDataLayoutTranslator
  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: FlexTypeNames.for(record) }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(dl)
    {
      unid: dl.id,
      uuid: dl.uuid,
      name: dl.name,
      layoutType: dl.layout_type || 0,
      priority: dl.priority || 0,
      enabled: dl.enabled.nil? ? true : dl.enabled,
      dataFormat: obj_ref(dl.data_format)
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:layout_type] = json["layoutType"] if json.key?("layoutType")
    attrs[:priority] = json["priority"] if json.key?("priority")
    attrs[:enabled] = json["enabled"] if json.key?("enabled")

    if json.key?("dataFormat")
      df = json["dataFormat"]
      if df.is_a?(Hash) && df["unid"]
        attrs[:data_format_id] = df["unid"]
      elsif df.is_a?(Hash) && df["uuid"]
        cf = CredentialFormat.find_by(uuid: df["uuid"])
        attrs[:data_format_id] = cf&.id
      end
    end

    attrs
  end
end
