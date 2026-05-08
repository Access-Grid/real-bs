require "test_helper"

class HolidayCalendarTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    hc = HolidayCalendar.create!(name: "US Federal")
    assert_not_nil hc.uuid
    assert_match(/\A[0-9a-f]{8}-/, hc.uuid)
  end

  test "does not overwrite existing uuid" do
    hc = HolidayCalendar.create!(name: "US Federal", uuid: "my-hc-uuid")
    assert_equal "my-hc-uuid", hc.uuid
  end

  test "uuid must be unique" do
    HolidayCalendar.create!(name: "Cal A", uuid: "dup-hc-uuid")
    dup = HolidayCalendar.new(name: "Cal B", uuid: "dup-hc-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    hc = HolidayCalendar.new
    assert_not hc.valid?
    assert_includes hc.errors[:name], "can't be blank"
  end

  test "has_many holidays" do
    hc = HolidayCalendar.create!(name: "US Federal")
    Holiday.create!(name: "New Year", holiday_calendar: hc, date: "2026-01-01")
    assert_equal 1, hc.holidays.count
  end

  test "destroying calendar destroys holidays" do
    hc = HolidayCalendar.create!(name: "US Federal")
    Holiday.create!(name: "New Year", holiday_calendar: hc)

    assert_difference "Holiday.count", -1 do
      hc.destroy
    end
  end
end
