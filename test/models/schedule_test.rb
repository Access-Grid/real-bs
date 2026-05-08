require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    s = Schedule.create!(name: "Business Hours")
    assert_not_nil s.uuid
    assert_match(/\A[0-9a-f]{8}-/, s.uuid)
  end

  test "does not overwrite existing uuid" do
    s = Schedule.create!(name: "Business Hours", uuid: "my-sched-uuid")
    assert_equal "my-sched-uuid", s.uuid
  end

  test "uuid must be unique" do
    Schedule.create!(name: "Sched A", uuid: "dup-sched-uuid")
    dup = Schedule.new(name: "Sched B", uuid: "dup-sched-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    s = Schedule.new
    assert_not s.valid?
    assert_includes s.errors[:name], "can't be blank"
  end

  test "has_many schedule_elements" do
    s = Schedule.create!(name: "Test")
    s.schedule_elements.create!(mon: true, start_time: "09:00", stop_time: "17:00")
    assert_equal 1, s.schedule_elements.count
  end

  test "destroying schedule destroys elements" do
    s = Schedule.create!(name: "Test")
    s.schedule_elements.create!(mon: true)
    assert_difference "ScheduleElement.count", -1 do
      s.destroy
    end
  end

  test "destroying schedule nullifies door_access_priv_elements" do
    s = Schedule.create!(name: "Test")
    controller_dev = IoController.create!(name: "Ctrl")
    door = Door.create!(name: "Door", physical_parent: controller_dev)
    ars = AccessRuleSet.create!(name: "ARS")
    el = ars.door_access_priv_elements.create!(door: door, schedule: s)

    s.destroy

    el.reload
    assert_nil el.schedule_id
  end
end
