require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    evt = Event.create!
    assert_not_nil evt.uuid
    assert_match(/\A[0-9a-f]{8}-/, evt.uuid)
  end

  test "does not overwrite existing uuid" do
    evt = Event.create!(uuid: "my-evt-uuid")
    assert_equal "my-evt-uuid", evt.uuid
  end

  test "uuid must be unique" do
    Event.create!(uuid: "dup-evt-uuid")
    dup = Event.new(uuid: "dup-evt-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "stores scalar fields" do
    evt = Event.create!(
      hw_time: "2026-04-16T10:30:00Z",
      db_time: "2026-04-16T10:30:01Z",
      hw_time_zone: "America/New_York",
      evt_code: 48,
      evt_sub_code: 0,
      priority: 0,
      data: "extra info",
      consumed: false
    )
    evt.reload
    assert_equal 48, evt.evt_code
    assert_equal 0, evt.evt_sub_code
    assert_equal 0, evt.priority
    assert_equal "extra info", evt.data
    assert_equal false, evt.consumed
    assert_equal "America/New_York", evt.hw_time_zone
  end

  test "stores external code fields" do
    evt = Event.create!(
      evt_code: 153,
      external_evt_code_text: "Custom Event",
      external_evt_code_id: "EXT-100",
      external_sub_code_text: "Custom Sub",
      external_sub_code_id: "EXT-SUB-1"
    )
    evt.reload
    assert_equal "Custom Event", evt.external_evt_code_text
    assert_equal "EXT-100", evt.external_evt_code_id
    assert_equal "Custom Sub", evt.external_sub_code_text
    assert_equal "EXT-SUB-1", evt.external_sub_code_id
  end

  test "stores JSON ref fields" do
    dev_ref = { "unid" => 1, "name" => "Front Door", "devType" => 5 }
    controller_ref = { "unid" => 2, "name" => "Main Controller", "devType" => 1 }
    cred_ref = { "unid" => 10, "name" => "Badge 001", "credNum" => "12345" }
    sched_ref = { "unid" => 5, "name" => "Business Hours", "invert" => false }
    modifiers = { "usedCard" => true, "usedPin" => false }

    evt = Event.create!(
      evt_dev_ref: dev_ref,
      evt_controller_ref: controller_ref,
      evt_cred_ref: cred_ref,
      evt_sched_ref: sched_ref,
      evt_modifiers: modifiers
    )
    evt.reload

    assert_equal "Front Door", evt.evt_dev_ref["name"]
    assert_equal "Main Controller", evt.evt_controller_ref["name"]
    assert_equal "Badge 001", evt.evt_cred_ref["name"]
    assert_equal "Business Hours", evt.evt_sched_ref["name"]
    assert_equal true, evt.evt_modifiers["usedCard"]
  end

  test "consumed defaults to false" do
    evt = Event.create!
    assert_equal false, evt.consumed
  end
end
