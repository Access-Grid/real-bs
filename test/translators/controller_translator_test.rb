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
    attrs = ControllerTranslator.from_flex({ "name" => "Panel", "devType" => 1, "bogusField" => "ignored" })
    assert_equal "Panel", attrs[:name]
    assert_nil attrs[:bogusField]
  end

  # -- New Dev base fields --

  test "to_flex maps externalId" do
    @io_controller.update!(external_id: "EXT-001")
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal "EXT-001", result[:externalId]
  end

  test "to_flex maps address and network fields" do
    @io_controller.update!(address: "192.168.1.100", port: 9000, speed: 9600, mac_address: "AA:BB:CC:DD:EE:FF")
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal "192.168.1.100", result[:address]
    assert_equal 9000, result[:port]
    assert_equal 9600, result[:speed]
    assert_equal "AA:BB:CC:DD:EE:FF", result[:macAddress]
  end

  test "to_flex maps devMod, devPlatform, devUse, devSubType" do
    @io_controller.update!(dev_mod: 164, dev_platform: 17, dev_use: 44, dev_sub_type: 7)
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal 164, result[:devMod]
    assert_equal 17, result[:devPlatform]
    assert_equal 44, result[:devUse]
    assert_equal 7, result[:devSubType]
  end

  test "to_flex maps timeZone and ignoreDaylightSavings" do
    @io_controller.update!(time_zone: "America/New_York", ignore_daylight_savings: true)
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal "America/New_York", result[:timeZone]
    assert_equal true, result[:ignoreDaylightSavings]
  end

  test "from_flex extracts all Dev base fields" do
    attrs = ControllerTranslator.from_flex({
      "name" => "Panel",
      "externalId" => "EXT-002",
      "address" => "10.0.0.1",
      "logicalAddress" => 5,
      "macAddress" => "11:22:33:44:55:66",
      "port" => 8080,
      "speed" => 115200,
      "devSubType" => 7,
      "devMod" => 164,
      "devPlatform" => 17,
      "devUse" => 44,
      "timeZone" => "US/Eastern",
      "ignoreDaylightSavings" => true
    })
    assert_equal "Panel", attrs[:name]
    assert_equal "EXT-002", attrs[:external_id]
    assert_equal "10.0.0.1", attrs[:address]
    assert_equal 5, attrs[:logical_address]
    assert_equal "11:22:33:44:55:66", attrs[:mac_address]
    assert_equal 8080, attrs[:port]
    assert_equal 115200, attrs[:speed]
    assert_equal 7, attrs[:dev_sub_type]
    assert_equal 164, attrs[:dev_mod]
    assert_equal 17, attrs[:dev_platform]
    assert_equal 44, attrs[:dev_use]
    assert_equal "US/Eastern", attrs[:time_zone]
    assert_equal true, attrs[:ignore_daylight_savings]
  end

  test "from_flex resolves physicalParent by unid" do
    parent = IoController.create!(name: "Parent Panel", sector: @sector)
    attrs = ControllerTranslator.from_flex({ "name" => "Child", "physicalParent" => { "unid" => parent.id } })
    assert_equal parent.id, attrs[:physical_parent_id]
  end

  test "from_flex resolves logicalParent by uuid" do
    parent = IoController.create!(name: "Parent Panel", sector: @sector)
    attrs = ControllerTranslator.from_flex({ "name" => "Child", "logicalParent" => { "uuid" => parent.uuid } })
    assert_equal parent.id, attrs[:logical_parent_id]
  end

  # -- ControllerConfig --

  test "to_flex returns controllerConfig with base fields from dev_config" do
    @io_controller.update!(dev_config: { "username" => "admin", "password" => "secret" })
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal "admin", result[:controllerConfig][:username]
    assert_equal "secret", result[:controllerConfig][:password]
  end

  test "to_flex returns empty controllerConfig when no dev_config" do
    result = ControllerTranslator.to_flex(@io_controller)
    assert_equal({}, result[:controllerConfig])
  end

  test "from_flex extracts controllerConfig into dev_config" do
    attrs = ControllerTranslator.from_flex({
      "name" => "Panel",
      "controllerConfig" => { "username" => "admin", "password" => "pass123" }
    })
    assert_equal "admin", attrs[:dev_config]["username"]
    assert_equal "pass123", attrs[:dev_config]["password"]
  end

  test "from_flex without controllerConfig does not set dev_config" do
    attrs = ControllerTranslator.from_flex({ "name" => "Panel" })
    assert_nil attrs[:dev_config]
  end
end
