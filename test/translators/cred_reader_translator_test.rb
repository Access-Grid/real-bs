require "test_helper"

class CredReaderTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @ac = AccessController.create!(name: "Panel 1", sector: @sector)
    @ew = EntryWay.create!(name: "Front Door", sector: @sector, access_controller: @ac)
    @reader = Reader.create!(name: "Card Reader 1", brand: "HID", model: "iClass", access_controller: @ac, entry_way: @ew)
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

  test "to_flex includes logicalParent for entry_way" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal @ew.id, result[:logicalParent][:unid]
  end

  test "to_flex includes physicalParent for access_controller" do
    result = CredReaderTranslator.to_flex(@reader)
    assert_equal @ac.id, result[:physicalParent][:unid]
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
