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
end
