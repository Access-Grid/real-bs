require "test_helper"

class EvtTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    evt = Event.create!(
      hw_time: "2026-04-16T10:30:00Z",
      db_time: "2026-04-16T10:30:01Z",
      hw_time_zone: "America/New_York",
      evt_code: 48,
      external_evt_code_text: nil,
      external_evt_code_id: nil,
      evt_sub_code: 0,
      external_sub_code_text: nil,
      external_sub_code_id: nil,
      priority: 0,
      data: "test data",
      consumed: false,
      evt_modifiers: { "usedCard" => true, "usedPin" => false },
      evt_dev_ref: { "unid" => 1, "name" => "Front Door" },
      evt_controller_ref: { "unid" => 2, "name" => "Controller" },
      evt_cred_ref: { "unid" => 10, "name" => "Badge 001" },
      evt_sched_ref: { "unid" => 5, "name" => "Business Hours" }
    )

    flex = EvtTranslator.to_flex(evt)

    assert_equal evt.id, flex[:unid]
    assert_equal evt.uuid, flex[:uuid]
    assert_not_nil flex[:hwTime]
    assert_not_nil flex[:dbTime]
    assert_equal "America/New_York", flex[:hwTimeZone]
    assert_equal 48, flex[:evtCode]
    assert_nil flex[:externalEvtCodeText]
    assert_equal 0, flex[:evtSubCode]
    assert_equal 0, flex[:priority]
    assert_equal "test data", flex[:data]
    assert_equal false, flex[:consumed]
    assert_equal({ "usedCard" => true, "usedPin" => false }, flex[:evtModifiers])
    assert_equal({ "unid" => 1, "name" => "Front Door" }, flex[:evtDevRef])
    assert_equal({ "unid" => 2, "name" => "Controller" }, flex[:evtControllerRef])
    assert_equal({ "unid" => 10, "name" => "Badge 001" }, flex[:evtCredRef])
    assert_equal({ "unid" => 5, "name" => "Business Hours" }, flex[:evtSchedRef])
  end

  test "to_flex handles nil timestamps" do
    evt = Event.create!
    flex = EvtTranslator.to_flex(evt)
    assert_nil flex[:hwTime]
    assert_nil flex[:dbTime]
  end

  test "to_flex defaults consumed to false" do
    evt = Event.create!
    flex = EvtTranslator.to_flex(evt)
    assert_equal false, flex[:consumed]
  end

  test "from_flex extracts all fields" do
    json = {
      "hwTime" => "2026-04-16T10:30:00Z",
      "dbTime" => "2026-04-16T10:30:01Z",
      "hwTimeZone" => "America/New_York",
      "evtCode" => 48,
      "externalEvtCodeText" => "Custom",
      "externalEvtCodeId" => "EXT-1",
      "evtSubCode" => 0,
      "externalSubCodeText" => "Sub Custom",
      "externalSubCodeId" => "EXT-SUB-1",
      "evtModifiers" => { "usedCard" => true },
      "priority" => 5,
      "data" => "some data",
      "evtDevRef" => { "unid" => 1 },
      "evtControllerRef" => { "unid" => 2 },
      "evtCredRef" => { "unid" => 10 },
      "evtSchedRef" => { "unid" => 5 },
      "consumed" => true
    }

    attrs = EvtTranslator.from_flex(json)

    assert_equal "2026-04-16T10:30:00Z", attrs[:hw_time]
    assert_equal "2026-04-16T10:30:01Z", attrs[:db_time]
    assert_equal "America/New_York", attrs[:hw_time_zone]
    assert_equal 48, attrs[:evt_code]
    assert_equal "Custom", attrs[:external_evt_code_text]
    assert_equal "EXT-1", attrs[:external_evt_code_id]
    assert_equal 0, attrs[:evt_sub_code]
    assert_equal "Sub Custom", attrs[:external_sub_code_text]
    assert_equal "EXT-SUB-1", attrs[:external_sub_code_id]
    assert_equal({ "usedCard" => true }, attrs[:evt_modifiers])
    assert_equal 5, attrs[:priority]
    assert_equal "some data", attrs[:data]
    assert_equal({ "unid" => 1 }, attrs[:evt_dev_ref])
    assert_equal({ "unid" => 2 }, attrs[:evt_controller_ref])
    assert_equal({ "unid" => 10 }, attrs[:evt_cred_ref])
    assert_equal({ "unid" => 5 }, attrs[:evt_sched_ref])
    assert_equal true, attrs[:consumed]
  end

  test "from_flex only includes present keys" do
    json = { "evtCode" => 48 }
    attrs = EvtTranslator.from_flex(json)
    assert_equal({ evt_code: 48 }, attrs)
    assert_not attrs.key?(:hw_time)
    assert_not attrs.key?(:priority)
  end
end
