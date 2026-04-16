require "test_helper"

class HolTypeTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    ht = HolidayType.create!(name: "Federal Holiday", external_id: "FED-1")

    flex = HolTypeTranslator.to_flex(ht)

    assert_equal ht.id, flex[:unid]
    assert_equal ht.uuid, flex[:uuid]
    assert_equal "FED-1", flex[:externalId]
    assert_equal "Federal Holiday", flex[:name]
  end

  test "from_flex extracts all fields" do
    json = { "name" => "Company Holiday", "externalId" => "CO-1" }
    attrs = HolTypeTranslator.from_flex(json)
    assert_equal "Company Holiday", attrs[:name]
    assert_equal "CO-1", attrs[:external_id]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = HolTypeTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:external_id)
  end

  test "obj_ref returns nil for nil" do
    assert_nil HolTypeTranslator.obj_ref(nil)
  end

  test "obj_ref returns ref hash" do
    ht = HolidayType.create!(name: "Federal")
    ref = HolTypeTranslator.obj_ref(ht)
    assert_equal ht.id, ref[:unid]
    assert_equal "Federal", ref[:name]
    assert_equal "HolidayType", ref[:type]
    assert_equal ht.uuid, ref[:uuid]
  end
end
