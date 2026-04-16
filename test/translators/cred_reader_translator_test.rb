require "test_helper"

class CredReaderTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @reader = CredReader.create!(name: "Card Reader 1", brand: "HID", model: "iClass", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "to_flex returns devType 4" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal 4, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal @reader.id, result[:unid]
    assert_equal @reader.uuid, result[:uuid]
    assert_equal "Card Reader 1", result[:name]
  end

  test "to_flex includes logicalParent for door" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal @door.id, result[:logicalParent][:unid]
  end

  test "to_flex includes physicalParent for controller" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal @io_controller.id, result[:physicalParent][:unid]
  end

  test "from_flex extracts name and metadata fields" do
    attrs = CredReaderTranslator.from_flex({
      "name" => "New Reader",
      "metadata" => { "brand" => "HID", "model" => "Signo", "serialNumber" => "ABC123" }
    })
    assert_equal "New Reader", attrs[:name]
    assert_equal "HID", attrs[:brand]
    assert_equal "Signo", attrs[:model]
    assert_equal "ABC123", attrs[:serial_number]
  end
end
