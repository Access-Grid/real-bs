class DoorAccessPrivTranslator
  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: record.class.name }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(ars)
    {
      unid: ars.id,
      uuid: ars.uuid,
      name: ars.name,
      privType: ars.priv_type || 0,
      enabled: ars.enabled.nil? ? true : ars.enabled,
      elements: ars.door_access_priv_elements.map { |el| element_to_flex(el) }
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:priv_type] = json["privType"] if json.key?("privType")
    attrs[:enabled] = json["enabled"] if json.key?("enabled")
    attrs
  end

  def self.save_elements(ars, elements_json)
    return unless elements_json.is_a?(Array)

    ars.door_access_priv_elements.destroy_all

    elements_json.each do |el|
      door_id = resolve_door_id(el["door"])
      next unless door_id

      ars.door_access_priv_elements.create!(
        door_id: door_id,
        sched_restriction_invert: el.dig("schedRestriction", "invert") || false
      )
    end
  end

  def self.element_to_flex(el)
    result = { door: obj_ref(el.door) }
    result[:schedRestriction] = {
      sched: nil,
      invert: el.sched_restriction_invert || false
    }
    result
  end

  def self.resolve_door_id(door_ref)
    return nil unless door_ref.is_a?(Hash)

    if door_ref["unid"]
      door_ref["unid"]
    elsif door_ref["uuid"]
      Door.find_by(uuid: door_ref["uuid"])&.id
    end
  end

  private_class_method :element_to_flex, :resolve_door_id
end
