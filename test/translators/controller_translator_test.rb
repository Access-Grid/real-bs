require "test_helper"

class ControllerTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Main Panel", brand: "Z9", model: "SP-Core", sector: @sector)
  end

  test "to_flex returns Dev JSON with devType 1" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal 1, result[:devType]
  end

  test "to_flex maps unid to Rails id" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal @io_controller.id, result[:unid]
  end

  test "to_flex maps uuid" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal @io_controller.uuid, result[:uuid]
  end

  test "to_flex maps name" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal "Main Panel", result[:name]
  end

  test "to_flex maps enabled" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal true, result[:enabled]
  end

  test "to_flex includes logicalChildren for doors" do
    door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    result = ControllerTranslator.to_flex(@io_controller.reload)
    children = result[:logicalChildren]
    assert_equal 1, children.length
    assert_equal door.name, children[0][:name]
    assert_equal door.id, children[0][:unid]
  end

  test "from_flex extracts name" do
    attrs = ControllerTranslator.from_flex({ "name" => "New Panel" })
    assert_equal "New Panel", attrs[:name]
  end

  test "from_flex extracts brand from metadata" do
    attrs = ControllerTranslator.from_flex({ "name" => "Panel", "metadata" => { "brand" => "HID" } })
    assert_equal "HID", attrs[:brand]
  end

  test "from_flex ignores unknown Flex fields" do
    attrs = ControllerTranslator.from_flex({ "name" => "Panel", "devType" => 1, "port" => 9000 })
    assert_equal "Panel", attrs[:name]
  end
end
