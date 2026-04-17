require "test_helper"

class DoorTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
  end

  test "to_flex returns devType 5" do
    result = DoorTranslator.to_flex(@door)
    assert_equal 5, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = DoorTranslator.to_flex(@door)
    assert_equal @door.id, result[:unid]
    assert_equal @door.uuid, result[:uuid]
    assert_equal "Front Door", result[:name]
  end

  test "to_flex includes logicalParent ObjRef for controller" do
    result = DoorTranslator.to_flex(@door)
    assert_equal @io_controller.id, result[:logicalParent][:unid]
    assert_equal @io_controller.name, result[:logicalParent][:name]
  end

  test "to_flex includes logicalChildren for readers and sensors" do
    CredReader.create!(name: "Reader 1", sector: @sector, logical_parent: @door, physical_parent: @io_controller)
    Sensor.create!(name: "Door Contact", sector: @sector, logical_parent: @door, physical_parent: @io_controller)
    result = DoorTranslator.to_flex(@door.reload)
    assert_equal 2, result[:logicalChildren].length
  end

  test "from_flex extracts name" do
    attrs = DoorTranslator.from_flex({ "name" => "Back Door" })
    assert_equal "Back Door", attrs[:name]
  end

  # -- DoorConfig --

  test "to_flex returns doorConfig with base fields" do
    @door.update!(dev_config: { "username" => "door_user", "password" => "dp" })
    result = DoorTranslator.to_flex(@door)
    assert_equal "door_user", result[:doorConfig][:username]
    assert_equal "dp", result[:doorConfig][:password]
  end

  test "to_flex returns doorConfig with unid and version when no dev_config" do
    result = DoorTranslator.to_flex(@door)
    assert_equal @door.id, result[:doorConfig][:unid]
    assert_equal 0, result[:doorConfig][:version]
  end

  test "to_flex returns doorConfig with door-specific fields" do
    @door.update!(dev_config: {
      "defaultDoorMode" => { "staticState" => 2, "allowCard" => true },
      "activateStrikeOnRex" => true,
      "strikeTime" => 5000,
      "extendedStrikeTime" => 10000,
      "heldTime" => 30000,
      "extendedHeldTime" => 60000
    })
    result = DoorTranslator.to_flex(@door)
    cfg = result[:doorConfig]
    assert_equal({ "staticState" => 2, "allowCard" => true }, cfg[:defaultDoorMode])
    assert_equal true, cfg[:activateStrikeOnRex]
    assert_equal 5000, cfg[:strikeTime]
    assert_equal 10000, cfg[:extendedStrikeTime]
    assert_equal 30000, cfg[:heldTime]
    assert_equal 60000, cfg[:extendedHeldTime]
  end

  test "from_flex extracts doorConfig into dev_config" do
    attrs = DoorTranslator.from_flex({
      "name" => "Door",
      "doorConfig" => {
        "username" => "admin",
        "defaultDoorMode" => { "staticState" => 2, "allowCard" => true },
        "activateStrikeOnRex" => true,
        "strikeTime" => 5000,
        "extendedStrikeTime" => 10000,
        "heldTime" => 30000,
        "extendedHeldTime" => 60000
      }
    })
    assert_equal "admin", attrs[:dev_config]["username"]
    assert_equal({ "staticState" => 2, "allowCard" => true }, attrs[:dev_config]["defaultDoorMode"])
    assert_equal true, attrs[:dev_config]["activateStrikeOnRex"]
    assert_equal 5000, attrs[:dev_config]["strikeTime"]
    assert_equal 10000, attrs[:dev_config]["extendedStrikeTime"]
    assert_equal 30000, attrs[:dev_config]["heldTime"]
    assert_equal 60000, attrs[:dev_config]["extendedHeldTime"]
  end

  test "from_flex without doorConfig does not set dev_config" do
    attrs = DoorTranslator.from_flex({ "name" => "Door" })
    assert_nil attrs[:dev_config]
  end
end
