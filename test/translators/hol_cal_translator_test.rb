require "test_helper"

class HolCalTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    hc = HolidayCalendar.create!(name: "US Federal")

    flex = HolCalTranslator.to_flex(hc)

    assert_equal hc.id, flex[:unid]
    assert_equal hc.uuid, flex[:uuid]
    assert_equal "US Federal", flex[:name]
  end

  test "from_flex extracts name" do
    json = { "name" => "Company Calendar" }
    attrs = HolCalTranslator.from_flex(json)
    assert_equal "Company Calendar", attrs[:name]
  end

  test "from_flex only includes present keys" do
    json = {}
    attrs = HolCalTranslator.from_flex(json)
    assert_equal({}, attrs)
  end

  test "obj_ref returns nil for nil" do
    assert_nil HolCalTranslator.obj_ref(nil)
  end

  test "obj_ref returns ref hash" do
    hc = HolidayCalendar.create!(name: "US Federal")
    ref = HolCalTranslator.obj_ref(hc)
    assert_equal hc.id, ref[:unid]
    assert_equal "US Federal", ref[:name]
    assert_equal "HolidayCalendar", ref[:type]
    assert_equal hc.uuid, ref[:uuid]
  end
end
