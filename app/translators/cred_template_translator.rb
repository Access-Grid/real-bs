class CredTemplateTranslator
  def self.to_flex(ct)
    {
      unid: ct.id,
      uuid: ct.uuid,
      version: ct.version_counter || 0,
      tag: ct.tag,
      name: ct.name,
      priority: ct.priority || 0,
      cardPinTemplate: ct.card_pin_template || {}
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:version_counter] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:priority] = json["priority"] if json.key?("priority")
    attrs[:card_pin_template] = json["cardPinTemplate"] if json.key?("cardPinTemplate")
    attrs
  end
end
