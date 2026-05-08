require "test_helper"

class HolidayTypeTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    ht = HolidayType.create!(name: "Federal Holiday")
    assert_not_nil ht.uuid
    assert_match(/\A[0-9a-f]{8}-/, ht.uuid)
  end

  test "does not overwrite existing uuid" do
    ht = HolidayType.create!(name: "Federal", uuid: "my-ht-uuid")
    assert_equal "my-ht-uuid", ht.uuid
  end

  test "uuid must be unique" do
    HolidayType.create!(name: "Type A", uuid: "dup-ht-uuid")
    dup = HolidayType.new(name: "Type B", uuid: "dup-ht-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    ht = HolidayType.new
    assert_not ht.valid?
    assert_includes ht.errors[:name], "can't be blank"
  end

  test "destroying holiday_type destroys schedule_element_holiday_types" do
    ht = HolidayType.create!(name: "Federal")
    s = Schedule.create!(name: "Test")
    el = s.schedule_elements.create!(holidays: true)
    el.schedule_element_holiday_types.create!(holiday_type: ht)

    assert_difference "ScheduleElementHolidayType.count", -1 do
      ht.destroy
    end
  end

  test "destroying holiday_type destroys holiday_holiday_types" do
    ht = HolidayType.create!(name: "Federal")
    hol = Holiday.create!(name: "New Year")
    hol.holiday_holiday_types.create!(holiday_type: ht)

    assert_difference "HolidayHolidayType.count", -1 do
      ht.destroy
    end
  end
end
