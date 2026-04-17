class HolTranslator
  def self.to_flex(hol)
    {
      unid: hol.id,
      uuid: hol.uuid,
      version: hol.version_counter || 0,
      tag: hol.tag,
      name: hol.name,
      holCal: HolCalTranslator.obj_ref(hol.holiday_calendar),
      holTypes: hol.holiday_types.map { |ht| HolTypeTranslator.obj_ref(ht) },
      date: hol.date&.iso8601,
      numDays: hol.num_days || 1,
      repeat: hol.repeat || false,
      numYearsRepeat: hol.num_years_repeat || 0,
      preserveSchedDay: hol.preserve_sched_day || false,
      allHolTypes: hol.all_hol_types || false
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:version_counter] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:date] = json["date"] if json.key?("date")
    attrs[:num_days] = json["numDays"] if json.key?("numDays")
    attrs[:repeat] = json["repeat"] if json.key?("repeat")
    attrs[:num_years_repeat] = json["numYearsRepeat"] if json.key?("numYearsRepeat")
    attrs[:preserve_sched_day] = json["preserveSchedDay"] if json.key?("preserveSchedDay")
    attrs[:all_hol_types] = json["allHolTypes"] if json.key?("allHolTypes")
    attrs[:holiday_calendar_id] = resolve_hol_cal_id(json["holCal"]) if json.key?("holCal")
    attrs
  end

  def self.save_hol_types(holiday, hol_types_json)
    return unless hol_types_json.is_a?(Array)

    holiday.holiday_holiday_types.destroy_all

    hol_types_json.each do |ht_ref|
      ht = resolve_holiday_type(ht_ref)
      next unless ht
      holiday.holiday_holiday_types.create!(holiday_type: ht)
    end
  end

  def self.resolve_hol_cal_id(ref)
    return nil unless ref.is_a?(Hash)

    if ref["unid"]
      ref["unid"]
    elsif ref["uuid"]
      HolidayCalendar.find_by(uuid: ref["uuid"])&.id
    end
  end

  def self.resolve_holiday_type(ref)
    return nil unless ref.is_a?(Hash)

    if ref["unid"]
      HolidayType.find_by(id: ref["unid"])
    elsif ref["uuid"]
      HolidayType.find_by(uuid: ref["uuid"])
    end
  end

  private_class_method :resolve_hol_cal_id, :resolve_holiday_type
end
