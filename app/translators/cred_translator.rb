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
      privBindings: cred.cred_priv_bindings.map { |b| binding_to_flex(b) }
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

  def self.save_priv_bindings(cred, bindings_json)
    return unless bindings_json.is_a?(Array)

    cred.cred_priv_bindings.destroy_all
    bindings_json.each do |b|
      cred.cred_priv_bindings.create!(
        access_rule_set_id: resolve_priv_id(b["priv"]),
        dev_as_door_access_priv_unid: resolve_dev_unid(b["devAsDoorAccessPriv"]),
        sched_restriction_invert: b.dig("schedRestriction", "invert") || false,
        schedule_id: resolve_schedule_id(b.dig("schedRestriction", "sched"))
      )
    end
  end

  def self.binding_to_flex(binding)
    result = { unid: binding.id }
    result[:priv] = DoorAccessPrivTranslator.obj_ref(binding.access_rule_set)
    result[:devAsDoorAccessPriv] = dev_as_door_obj_ref(binding.dev_as_door_access_priv_unid)
    result[:schedRestriction] = {
      sched: SchedTranslator.obj_ref(binding.schedule),
      invert: binding.sched_restriction_invert || false
    }
    result
  end

  def self.resolve_priv_id(priv_ref)
    return nil unless priv_ref.is_a?(Hash)

    if priv_ref["unid"]
      priv_ref["unid"]
    elsif priv_ref["uuid"]
      AccessRuleSet.find_by(uuid: priv_ref["uuid"])&.id
    end
  end

  def self.resolve_dev_unid(dev_ref)
    return nil unless dev_ref.is_a?(Hash)
    dev_ref["unid"]
  end

  def self.resolve_schedule_id(sched_ref)
    return nil unless sched_ref.is_a?(Hash)

    if sched_ref["unid"]
      sched_ref["unid"]
    elsif sched_ref["uuid"]
      Schedule.find_by(uuid: sched_ref["uuid"])&.id
    end
  end

  def self.dev_as_door_obj_ref(dev_unid)
    return nil unless dev_unid
    dev = Device.find_by(id: dev_unid)
    return nil unless dev
    ref = { unid: dev.id, name: dev.name, type: dev.class.name }
    ref[:uuid] = dev.uuid if dev.uuid
    ref
  end

  private_class_method :binding_to_flex, :resolve_priv_id, :resolve_dev_unid,
                       :resolve_schedule_id, :dev_as_door_obj_ref
end
