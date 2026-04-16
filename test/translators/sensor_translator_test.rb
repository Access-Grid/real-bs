require "test_helper"

class SensorTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @sensor = Sensor.create!(name: "Door Contact", brand: "Z9", model: "DC-100", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "to_flex returns devType 2" do
    result = SensorTranslator.to_flex(@sensor)
    assert_equal 2, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = SensorTranslator.to_flex(@sensor)
    assert_equal @sensor.id, result[:unid]
    assert_equal @sensor.uuid, result[:uuid]
    assert_equal "Door Contact", result[:name]
  end

  test "to_flex includes logicalParent for door" do
    result = SensorTranslator.to_flex(@sensor)
    assert_equal @door.id, result[:logicalParent][:unid]
  end

  test "from_flex extracts name and metadata fields" do
    attrs = SensorTranslator.from_flex({
      "name" => "REX Sensor",
      "metadata" => { "brand" => "Z9", "serialNumber" => "XYZ789" }
    })
    assert_equal "REX Sensor", attrs[:name]
    assert_equal "Z9", attrs[:brand]
    assert_equal "XYZ789", attrs[:serial_number]
  end
end
