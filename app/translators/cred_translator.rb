class CredTranslator
  def self.obj_ref(record)
    return nil unless record
    name = if record.respond_to?(:name)
             record.name
           elsif record.respond_to?(:first_name)
             [record.first_name, record.last_name].compact.join(" ")
           end
    ref = { unid: record.id, name: name, type: record.class.name }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(cred)
    result = {
      unid: cred.id,
      uuid: cred.uuid,
      name: cred.name,
      enabled: cred.enabled,
      effective: cred.effective&.iso8601,
      expires: cred.expires&.iso8601,
      cardPin: cred.card_pin || {},
      credTemplate: obj_ref(cred.credential_type),
      credHolder: obj_ref(cred.person),
      privBindings: []
    }
    result
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:enabled] = json["enabled"] if json.key?("enabled")
    attrs[:effective] = json["effective"] if json.key?("effective")
    attrs[:expires] = json["expires"] if json.key?("expires")
    attrs[:card_pin] = json["cardPin"] if json.key?("cardPin")

    if json.key?("credTemplate")
      ct = json["credTemplate"]
      if ct.is_a?(Hash) && ct["unid"]
        attrs[:credential_type_id] = ct["unid"]
      elsif ct.is_a?(Hash) && ct["uuid"]
        ct_record = CredentialType.find_by(uuid: ct["uuid"])
        attrs[:credential_type_id] = ct_record&.id
      end
    end

    if json.key?("credHolder")
      ch = json["credHolder"]
      if ch.is_a?(Hash) && ch["unid"]
        attrs[:person_id] = ch["unid"]
      end
    end

    attrs
  end
end
