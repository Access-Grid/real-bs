require "test_helper"

class HolidayTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    h = Holiday.create!(name: "New Year")
    assert_not_nil h.uuid
    assert_match(/\A[0-9a-f]{8}-/, h.uuid)
  end

  test "does not overwrite existing uuid" do
    h = Holiday.create!(name: "New Year", uuid: "my-hol-uuid")
    assert_equal "my-hol-uuid", h.uuid
  end

  test "uuid must be unique" do
    Holiday.create!(name: "Hol A", uuid: "dup-hol-uuid")
    dup = Holiday.new(name: "Hol B", uuid: "dup-hol-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    h = Holiday.new
    assert_not h.valid?
    assert_includes h.errors[:name], "can't be blank"
  end

  test "holiday_calendar is optional" do
    h = Holiday.create!(name: "Standalone Holiday")
    assert_nil h.holiday_calendar
  end

  test "belongs to holiday_calendar" do
    hc = HolidayCalendar.create!(name: "US Federal")
    h = Holiday.create!(name: "New Year", holiday_calendar: hc)
    assert_equal hc, h.holiday_calendar
  end

  test "has_many holiday_types through holiday_holiday_types" do
    ht = HolidayType.create!(name: "Federal")
    h = Holiday.create!(name: "New Year")
    h.holiday_holiday_types.create!(holiday_type: ht)

    assert_equal 1, h.holiday_types.count
    assert_equal ht, h.holiday_types.first
  end

  test "destroying holiday destroys join records" do
    ht = HolidayType.create!(name: "Federal")
    h = Holiday.create!(name: "New Year")
    h.holiday_holiday_types.create!(holiday_type: ht)

    assert_difference "HolidayHolidayType.count", -1 do
      h.destroy
    end
  end

  test "defaults" do
    h = Holiday.create!(name: "Test")
    assert_equal 1, h.num_days
    assert_equal false, h.repeat
    assert_equal 0, h.num_years_repeat
    assert_equal false, h.preserve_sched_day
    assert_equal false, h.all_hol_types
  end
end
