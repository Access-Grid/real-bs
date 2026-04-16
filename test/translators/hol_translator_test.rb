require "test_helper"

class HolTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    hc = HolidayCalendar.create!(name: "US Federal")
    ht = HolidayType.create!(name: "Federal")
    hol = Holiday.create!(
      name: "New Year",
      holiday_calendar: hc,
      date: "2026-01-01",
      num_days: 1,
      repeat: true,
      num_years_repeat: 5,
      preserve_sched_day: true,
      all_hol_types: false
    )
    hol.holiday_holiday_types.create!(holiday_type: ht)

    flex = HolTranslator.to_flex(hol)

    assert_equal hol.id, flex[:unid]
    assert_equal hol.uuid, flex[:uuid]
    assert_equal "New Year", flex[:name]
    assert_equal "2026-01-01", flex[:date]
    assert_equal 1, flex[:numDays]
    assert_equal true, flex[:repeat]
    assert_equal 5, flex[:numYearsRepeat]
    assert_equal true, flex[:preserveSchedDay]
    assert_equal false, flex[:allHolTypes]

    assert_not_nil flex[:holCal]
    assert_equal hc.id, flex[:holCal][:unid]
    assert_equal "US Federal", flex[:holCal][:name]

    assert_equal 1, flex[:holTypes].length
    assert_equal ht.id, flex[:holTypes][0][:unid]
  end

  test "to_flex with nil holiday_calendar" do
    hol = Holiday.create!(name: "Standalone")
    flex = HolTranslator.to_flex(hol)
    assert_nil flex[:holCal]
  end

  test "to_flex defaults" do
    hol = Holiday.create!(name: "Basic")
    flex = HolTranslator.to_flex(hol)
    assert_equal 1, flex[:numDays]
    assert_equal false, flex[:repeat]
    assert_equal 0, flex[:numYearsRepeat]
    assert_equal false, flex[:preserveSchedDay]
    assert_equal false, flex[:allHolTypes]
    assert_equal [], flex[:holTypes]
  end

  test "from_flex extracts all fields" do
    hc = HolidayCalendar.create!(name: "US Federal")
    json = {
      "name" => "Independence Day",
      "date" => "2026-07-04",
      "numDays" => 1,
      "repeat" => true,
      "numYearsRepeat" => 10,
      "preserveSchedDay" => false,
      "allHolTypes" => true,
      "holCal" => { "unid" => hc.id }
    }

    attrs = HolTranslator.from_flex(json)

    assert_equal "Independence Day", attrs[:name]
    assert_equal "2026-07-04", attrs[:date]
    assert_equal 1, attrs[:num_days]
    assert_equal true, attrs[:repeat]
    assert_equal 10, attrs[:num_years_repeat]
    assert_equal false, attrs[:preserve_sched_day]
    assert_equal true, attrs[:all_hol_types]
    assert_equal hc.id, attrs[:holiday_calendar_id]
  end

  test "from_flex resolves holCal by uuid" do
    hc = HolidayCalendar.create!(name: "Company")
    json = { "name" => "Holiday", "holCal" => { "uuid" => hc.uuid } }
    attrs = HolTranslator.from_flex(json)
    assert_equal hc.id, attrs[:holiday_calendar_id]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = HolTranslator.from_flex(json)
    assert_equal "Minimal", attrs[:name]
    assert_not attrs.key?(:date)
    assert_not attrs.key?(:num_days)
    assert_not attrs.key?(:holiday_calendar_id)
  end

  test "save_hol_types creates join records" do
    ht1 = HolidayType.create!(name: "Federal")
    ht2 = HolidayType.create!(name: "Company")
    hol = Holiday.create!(name: "Test")

    HolTranslator.save_hol_types(hol, [{ "unid" => ht1.id }, { "unid" => ht2.id }])

    assert_equal 2, hol.holiday_types.count
  end

  test "save_hol_types replaces existing join records" do
    ht1 = HolidayType.create!(name: "Federal")
    ht2 = HolidayType.create!(name: "Company")
    hol = Holiday.create!(name: "Test")
    hol.holiday_holiday_types.create!(holiday_type: ht1)

    HolTranslator.save_hol_types(hol, [{ "unid" => ht2.id }])

    assert_equal 1, hol.holiday_types.count
    assert_equal ht2, hol.holiday_types.first
  end

  test "save_hol_types resolves by uuid" do
    ht = HolidayType.create!(name: "Federal")
    hol = Holiday.create!(name: "Test")

    HolTranslator.save_hol_types(hol, [{ "uuid" => ht.uuid }])

    assert_equal ht, hol.holiday_types.first
  end

  test "save_hol_types skips unresolvable" do
    hol = Holiday.create!(name: "Test")
    HolTranslator.save_hol_types(hol, [{ "uuid" => "nonexistent" }])
    assert_equal 0, hol.holiday_types.count
  end

  test "save_hol_types does nothing when not an array" do
    ht = HolidayType.create!(name: "Federal")
    hol = Holiday.create!(name: "Test")
    hol.holiday_holiday_types.create!(holiday_type: ht)

    HolTranslator.save_hol_types(hol, nil)

    assert_equal 1, hol.holiday_types.count
  end
end
