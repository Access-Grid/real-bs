require "test_helper"

class DevTranslatorBaseTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
  end

  # -- translator_for --

  test "translator_for returns ControllerTranslator for IoController" do
    dev = IoController.create!(name: "Panel", sector: @sector)
    assert_equal ControllerTranslator, DevTranslatorBase.translator_for(dev)
  end

  test "translator_for returns DoorTranslator for Door" do
    dev = Door.create!(name: "Door", sector: @sector)
    assert_equal DoorTranslator, DevTranslatorBase.translator_for(dev)
  end

  test "translator_for returns CredReaderTranslator for CredReader" do
    dev = CredReader.create!(name: "Reader", sector: @sector)
    assert_equal CredReaderTranslator, DevTranslatorBase.translator_for(dev)
  end

  test "translator_for returns SensorTranslator for Sensor" do
    dev = Sensor.create!(name: "Sensor", sector: @sector)
    assert_equal SensorTranslator, DevTranslatorBase.translator_for(dev)
  end

  test "translator_for returns ActuatorTranslator for Actuator" do
    dev = Actuator.create!(name: "Actuator", sector: @sector)
    assert_equal ActuatorTranslator, DevTranslatorBase.translator_for(dev)
  end

  test "translator_for returns NodeDevTranslator for NodeDev" do
    dev = NodeDev.create!(name: "Node", sector: @sector)
    assert_equal NodeDevTranslator, DevTranslatorBase.translator_for(dev)
  end

  # -- class_for_dev_type --

  test "class_for_dev_type maps 0 to NodeDev" do
    assert_equal NodeDev, DevTranslatorBase.class_for_dev_type(0)
  end

  test "class_for_dev_type maps 1 to IoController" do
    assert_equal IoController, DevTranslatorBase.class_for_dev_type(1)
  end

  test "class_for_dev_type maps 2 to Sensor" do
    assert_equal Sensor, DevTranslatorBase.class_for_dev_type(2)
  end

  test "class_for_dev_type maps 3 to Actuator" do
    assert_equal Actuator, DevTranslatorBase.class_for_dev_type(3)
  end

  test "class_for_dev_type maps 4 to CredReader" do
    assert_equal CredReader, DevTranslatorBase.class_for_dev_type(4)
  end

  test "class_for_dev_type maps 5 to Door" do
    assert_equal Door, DevTranslatorBase.class_for_dev_type(5)
  end

  test "class_for_dev_type returns nil for unknown type" do
    assert_nil DevTranslatorBase.class_for_dev_type(99)
  end

  # -- base_dev_fields with new fields --

  test "base_dev_fields includes all swagger Dev fields" do
    dev = IoController.create!(
      name: "Full Panel",
      sector: @sector,
      external_id: "EXT-100",
      address: "192.168.1.50",
      logical_address: 3,
      mac_address: "AA:BB:CC:DD:EE:FF",
      port: 9000,
      speed: 9600,
      dev_sub_type: 7,
      dev_mod: 164,
      dev_platform: 17,
      dev_use: 44,
      time_zone: "America/New_York",
      ignore_daylight_savings: true
    )
    result = DevTranslatorBase.base_dev_fields(dev)

    assert_equal "EXT-100", result[:externalId]
    assert_equal "192.168.1.50", result[:address]
    assert_equal 3, result[:logicalAddress]
    assert_equal "AA:BB:CC:DD:EE:FF", result[:macAddress]
    assert_equal 9000, result[:port]
    assert_equal 9600, result[:speed]
    assert_equal 7, result[:devSubType]
    assert_equal 164, result[:devMod]
    assert_equal 17, result[:devPlatform]
    assert_equal 44, result[:devUse]
    assert_equal "America/New_York", result[:timeZone]
    assert_equal true, result[:ignoreDaylightSavings]
  end

  test "base_dev_fields nil fields are returned as nil" do
    dev = IoController.create!(name: "Minimal", sector: @sector)
    result = DevTranslatorBase.base_dev_fields(dev)
    assert_nil result[:externalId]
    assert_nil result[:address]
    assert_nil result[:port]
    assert_nil result[:devMod]
  end

  # -- base_from_flex with new fields --

  test "base_from_flex extracts all Dev base fields" do
    attrs = DevTranslatorBase.base_from_flex({
      "name" => "Panel",
      "externalId" => "EXT-200",
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
      "ignoreDaylightSavings" => true,
      "devModConfig" => { "username" => "admin" }
    })

    assert_equal "EXT-200", attrs[:external_id]
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
    assert_equal({ "username" => "admin" }, attrs[:dev_mod_config])
  end

  test "base_from_flex only sets keys present in input" do
    attrs = DevTranslatorBase.base_from_flex({ "name" => "Panel" })
    assert_equal "Panel", attrs[:name]
    assert_not attrs.key?(:external_id)
    assert_not attrs.key?(:address)
    assert_not attrs.key?(:port)
  end
end
