require "test_helper"

class SchedTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    s = Schedule.create!(name: "Business Hours", external_id: "EXT-1")
    s.schedule_elements.create!(
      mon: true, tues: true, wed: true, thur: true, fri: true,
      sat: false, sun: false,
      holidays: false,
      start_time: "09:00", stop_time: "17:00", plus_days: 0
    )

    flex = SchedTranslator.to_flex(s)

    assert_equal s.id, flex[:unid]
    assert_equal s.uuid, flex[:uuid]
    assert_equal "EXT-1", flex[:externalId]
    assert_equal "Business Hours", flex[:name]
    assert_equal 1, flex[:elements].length

    elem = flex[:elements][0]
    assert_equal s.schedule_elements.first.id, elem[:unid]
    assert_equal [0, 1, 2, 3, 4], elem[:schedDays]
    assert_equal "09:00", elem[:start]
    assert_equal "17:00", elem[:stop]
    assert_equal 0, elem[:plusDays]
    assert_equal false, elem[:holidays]
    assert_equal [], elem[:holTypes]
  end

  test "to_flex maps all 7 days" do
    s = Schedule.create!(name: "Every Day")
    s.schedule_elements.create!(
      mon: true, tues: true, wed: true, thur: true,
      fri: true, sat: true, sun: true
    )

    flex = SchedTranslator.to_flex(s)
    assert_equal [0, 1, 2, 3, 4, 5, 6], flex[:elements][0][:schedDays]
  end

  test "to_flex returns empty elements when none exist" do
    s = Schedule.create!(name: "Empty")
    flex = SchedTranslator.to_flex(s)
    assert_equal [], flex[:elements]
  end

  test "to_flex includes holTypes ObjRefs on elements" do
    ht = HolidayType.create!(name: "Federal")
    s = Schedule.create!(name: "With HolType")
    el = s.schedule_elements.create!(holidays: true)
    el.schedule_element_holiday_types.create!(holiday_type: ht)

    flex = SchedTranslator.to_flex(s)
    hol_types = flex[:elements][0][:holTypes]
    assert_equal 1, hol_types.length
    assert_equal ht.id, hol_types[0][:unid]
    assert_equal "Federal", hol_types[0][:name]
    assert_equal "HolType", hol_types[0][:type]
    assert_equal ht.uuid, hol_types[0][:uuid]
  end

  test "from_flex extracts name and externalId" do
    json = { "name" => "Night Shift", "externalId" => "EXT-2" }
    attrs = SchedTranslator.from_flex(json)
    assert_equal "Night Shift", attrs[:name]
    assert_equal "EXT-2", attrs[:external_id]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = SchedTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:external_id)
  end

  test "save_elements creates elements with day booleans from schedDays" do
    s = Schedule.create!(name: "Test")
    elements_json = [
      {
        "schedDays" => [0, 2, 4],
        "start" => "08:00",
        "stop" => "16:00",
        "plusDays" => 1,
        "holidays" => false
      }
    ]

    SchedTranslator.save_elements(s, elements_json)

    assert_equal 1, s.schedule_elements.count
    el = s.schedule_elements.first
    assert_equal true, el.mon
    assert_equal false, el.tues
    assert_equal true, el.wed
    assert_equal false, el.thur
    assert_equal true, el.fri
    assert_equal false, el.sat
    assert_equal false, el.sun
    assert_equal "08:00", el.start_time
    assert_equal "16:00", el.stop_time
    assert_equal 1, el.plus_days
  end

  test "save_elements replaces existing elements" do
    s = Schedule.create!(name: "Test")
    s.schedule_elements.create!(mon: true)

    elements_json = [
      { "schedDays" => [5, 6], "start" => "10:00", "stop" => "14:00" }
    ]

    SchedTranslator.save_elements(s, elements_json)

    assert_equal 1, s.schedule_elements.count
    el = s.schedule_elements.first
    assert_equal false, el.mon
    assert_equal true, el.sat
    assert_equal true, el.sun
  end

  test "save_elements creates holType join records" do
    ht = HolidayType.create!(name: "Federal")
    s = Schedule.create!(name: "Test")
    elements_json = [
      {
        "schedDays" => [],
        "holidays" => true,
        "holTypes" => [{ "unid" => ht.id }]
      }
    ]

    SchedTranslator.save_elements(s, elements_json)

    el = s.schedule_elements.first
    assert_equal 1, el.holiday_types.count
    assert_equal ht, el.holiday_types.first
  end

  test "save_elements resolves holTypes by uuid" do
    ht = HolidayType.create!(name: "Company")
    s = Schedule.create!(name: "Test")
    elements_json = [
      {
        "schedDays" => [],
        "holidays" => true,
        "holTypes" => [{ "uuid" => ht.uuid }]
      }
    ]

    SchedTranslator.save_elements(s, elements_json)

    el = s.schedule_elements.first
    assert_equal ht, el.holiday_types.first
  end

  test "save_elements skips unresolvable holTypes" do
    s = Schedule.create!(name: "Test")
    elements_json = [
      {
        "schedDays" => [],
        "holidays" => true,
        "holTypes" => [{ "uuid" => "nonexistent" }]
      }
    ]

    SchedTranslator.save_elements(s, elements_json)

    el = s.schedule_elements.first
    assert_equal 0, el.holiday_types.count
  end

  test "save_elements does nothing when not an array" do
    s = Schedule.create!(name: "Test")
    s.schedule_elements.create!(mon: true)

    SchedTranslator.save_elements(s, nil)

    assert_equal 1, s.schedule_elements.count
  end

  test "obj_ref returns nil for nil" do
    assert_nil SchedTranslator.obj_ref(nil)
  end

  test "obj_ref returns ref hash" do
    s = Schedule.create!(name: "Test")
    ref = SchedTranslator.obj_ref(s)
    assert_equal s.id, ref[:unid]
    assert_equal "Test", ref[:name]
    assert_equal "Sched", ref[:type]
    assert_equal s.uuid, ref[:uuid]
  end
end
