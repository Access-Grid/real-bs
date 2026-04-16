class CredTemplateTranslator
  def self.to_flex(ct)
    {
      unid: ct.id,
      uuid: ct.uuid,
      name: ct.name,
      priority: ct.priority || 0,
      cardPinTemplate: ct.card_pin_template || {},
      kind: ct.kind,
      frequency: ct.frequency,
      protocol: ct.protocol
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:priority] = json["priority"] if json.key?("priority")
    attrs[:card_pin_template] = json["cardPinTemplate"] if json.key?("cardPinTemplate")
    attrs[:kind] = json["kind"] if json.key?("kind")
    attrs[:frequency] = json["frequency"] if json.key?("frequency")
    attrs[:protocol] = json["protocol"] if json.key?("protocol")
    attrs
  end
end
