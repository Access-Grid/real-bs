require "test_helper"

class ScheduleElementTest < ActiveSupport::TestCase
  setup do
    @schedule = Schedule.create!(name: "Business Hours")
  end

  test "belongs to schedule" do
    el = @schedule.schedule_elements.create!(mon: true, start_time: "09:00", stop_time: "17:00")
    assert_equal @schedule, el.schedule
  end

  test "day columns default to false" do
    el = @schedule.schedule_elements.create!
    assert_equal false, el.mon
    assert_equal false, el.tues
    assert_equal false, el.wed
    assert_equal false, el.thur
    assert_equal false, el.fri
    assert_equal false, el.sat
    assert_equal false, el.sun
  end

  test "holidays defaults to false" do
    el = @schedule.schedule_elements.create!
    assert_equal false, el.holidays
  end

  test "plus_days defaults to 0" do
    el = @schedule.schedule_elements.create!
    assert_equal 0, el.plus_days
  end

  test "has_many holiday_types through schedule_element_holiday_types" do
    ht = HolidayType.create!(name: "Federal")
    el = @schedule.schedule_elements.create!(holidays: true)
    el.schedule_element_holiday_types.create!(holiday_type: ht)

    assert_equal 1, el.holiday_types.count
    assert_equal ht, el.holiday_types.first
  end

  test "destroying element destroys join records" do
    ht = HolidayType.create!(name: "Federal")
    el = @schedule.schedule_elements.create!(holidays: true)
    el.schedule_element_holiday_types.create!(holiday_type: ht)

    assert_difference "ScheduleElementHolidayType.count", -1 do
      el.destroy
    end
  end
end
