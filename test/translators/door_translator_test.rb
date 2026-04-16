require "test_helper"

class DoorTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @ac = AccessController.create!(name: "Panel 1", sector: @sector)
    @ew = EntryWay.create!(name: "Front Door", sector: @sector, access_controller: @ac)
  end

  test "to_flex returns devType 5" do
    result = DoorTranslator.to_flex(@ew)
    assert_equal 5, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = DoorTranslator.to_flex(@ew)
    assert_equal @ew.id, result[:unid]
    assert_equal @ew.uuid, result[:uuid]
    assert_equal "Front Door", result[:name]
  end

  test "to_flex includes logicalParent ObjRef for access_controller" do
    result = DoorTranslator.to_flex(@ew)
    assert_equal @ac.id, result[:logicalParent][:unid]
    assert_equal @ac.name, result[:logicalParent][:name]
  end

  test "to_flex includes logicalChildren for readers and sensors" do
    reader = Reader.create!(name: "Reader 1", access_controller: @ac, entry_way: @ew)
    sensor = Sensor.create!(name: "Door Contact", access_controller: @ac, entry_way: @ew)
    result = DoorTranslator.to_flex(@ew.reload)
    assert_equal 2, result[:logicalChildren].length
  end

  test "from_flex extracts name" do
    attrs = DoorTranslator.from_flex({ "name" => "Back Door" })
    assert_equal "Back Door", attrs[:name]
  end
end
