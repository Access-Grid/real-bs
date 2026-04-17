class SchedTranslator
  DAY_COLUMNS = { 0 => :mon, 1 => :tues, 2 => :wed, 3 => :thur, 4 => :fri, 5 => :sat, 6 => :sun }.freeze

  def self.obj_ref(record)
    return nil unless record
    ref = { unid: record.id, name: record.name, type: FlexTypeNames.for(record) }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(schedule)
    {
      unid: schedule.id,
      uuid: schedule.uuid,
      externalId: schedule.external_id,
      name: schedule.name,
      elements: schedule.schedule_elements.map { |el| element_to_flex(el) }
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:name] = json["name"] if json.key?("name")
    attrs[:external_id] = json["externalId"] if json.key?("externalId")
    attrs
  end

  def self.save_elements(schedule, elements_json)
    return unless elements_json.is_a?(Array)

    schedule.schedule_elements.destroy_all

    elements_json.each do |el|
      elem = schedule.schedule_elements.create!(
        holidays: el["holidays"] || false,
        start_time: el["start"],
        stop_time: el["stop"],
        plus_days: el["plusDays"] || 0,
        **days_from_flex(el["schedDays"])
      )

      save_element_hol_types(elem, el["holTypes"]) if el["holTypes"].is_a?(Array)
    end
  end

  def self.element_to_flex(el)
    result = {
      unid: el.id,
      holidays: el.holidays || false,
      schedDays: days_to_flex(el),
      start: el.start_time,
      stop: el.stop_time,
      plusDays: el.plus_days || 0,
      holTypes: el.holiday_types.map { |ht| HolTypeTranslator.obj_ref(ht) }
    }
    result
  end

  def self.days_to_flex(el)
    days = []
    DAY_COLUMNS.each do |index, col|
      days << index if el.send(col)
    end
    days
  end

  def self.days_from_flex(sched_days)
    day_attrs = DAY_COLUMNS.values.each_with_object({}) { |col, h| h[col] = false }
    return day_attrs unless sched_days.is_a?(Array)

    sched_days.each do |day_index|
      col = DAY_COLUMNS[day_index]
      day_attrs[col] = true if col
    end
    day_attrs
  end

  def self.save_element_hol_types(elem, hol_types_json)
    hol_types_json.each do |ht_ref|
      ht = resolve_holiday_type(ht_ref)
      next unless ht
      elem.schedule_element_holiday_types.create!(holiday_type: ht)
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

  private_class_method :element_to_flex, :days_to_flex, :days_from_flex,
                       :save_element_hol_types, :resolve_holiday_type
end
