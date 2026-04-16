require "test_helper"

class ActuatorTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @actuator = Actuator.create!(name: "Door Strike", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "to_flex returns devType 3" do
    result = ActuatorTranslator.to_flex(@actuator)
    assert_equal 3, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = ActuatorTranslator.to_flex(@actuator)
    assert_equal @actuator.id, result[:unid]
    assert_equal @actuator.uuid, result[:uuid]
    assert_equal "Door Strike", result[:name]
  end

  test "to_flex includes actuatorConfig" do
    result = ActuatorTranslator.to_flex(@actuator)
    assert_equal({}, result[:actuatorConfig])
  end

  test "to_flex includes logicalParent" do
    result = ActuatorTranslator.to_flex(@actuator)
    assert_equal @door.id, result[:logicalParent][:unid]
  end

  test "from_flex extracts name and metadata fields" do
    attrs = ActuatorTranslator.from_flex({
      "name" => "Relay Output",
      "metadata" => { "brand" => "Z9", "model" => "RO-100" }
    })
    assert_equal "Relay Output", attrs[:name]
    assert_equal "Z9", attrs[:brand]
    assert_equal "RO-100", attrs[:model]
  end
end
