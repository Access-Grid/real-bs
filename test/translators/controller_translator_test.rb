require "test_helper"

class ControllerTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @ac = AccessController.create!(name: "Main Panel", brand: "Z9", model: "SP-Core", sector: @sector)
  end

  test "to_flex returns Dev JSON with correct devType" do
    result = ControllerTranslator.to_flex(@ac)
    assert_equal 1, result[:devType]
  end

  test "to_flex maps unid to Rails id" do
    result = ControllerTranslator.to_flex(@ac)
    assert_equal @ac.id, result[:unid]
  end

  test "to_flex maps uuid" do
    result = ControllerTranslator.to_flex(@ac)
    assert_equal @ac.uuid, result[:uuid]
  end

  test "to_flex maps name" do
    result = ControllerTranslator.to_flex(@ac)
    assert_equal "Main Panel", result[:name]
  end

  test "to_flex maps enabled based on presence" do
    result = ControllerTranslator.to_flex(@ac)
    assert_equal true, result[:enabled]
  end

  test "to_flex includes physicalParent ObjRef for sector" do
    result = ControllerTranslator.to_flex(@ac)
    parent = result[:physicalParent]
    assert_not_nil parent
    assert_equal @sector.name, parent[:name]
    assert_equal @sector.id, parent[:unid]
  end

  test "to_flex includes logicalChildren ObjRefs for entry_ways" do
    ew = EntryWay.create!(name: "Front Door", sector: @sector, access_controller: @ac)
    result = ControllerTranslator.to_flex(@ac.reload)
    children = result[:logicalChildren]
    assert_equal 1, children.length
    assert_equal ew.name, children[0][:name]
    assert_equal ew.id, children[0][:unid]
  end

  test "from_flex extracts name from Dev JSON" do
    flex_json = { "name" => "New Panel" }
    attrs = ControllerTranslator.from_flex(flex_json)
    assert_equal "New Panel", attrs[:name]
  end

  test "from_flex extracts brand from metadata" do
    flex_json = { "name" => "Panel", "metadata" => { "brand" => "HID" } }
    attrs = ControllerTranslator.from_flex(flex_json)
    assert_equal "HID", attrs[:brand]
  end

  test "from_flex ignores unknown Flex fields gracefully" do
    flex_json = { "name" => "Panel", "devType" => 1, "port" => 9000, "speed" => 115200 }
    attrs = ControllerTranslator.from_flex(flex_json)
    assert_equal "Panel", attrs[:name]
  end
end
