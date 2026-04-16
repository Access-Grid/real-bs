require "test_helper"

class NodeDevTranslatorTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @node_dev = NodeDev.create!(name: "Server Node", sector: @sector)
  end

  test "to_flex returns devType 0" do
    result = NodeDevTranslator.to_flex(@node_dev)
    assert_equal 0, result[:devType]
  end

  test "to_flex maps unid, uuid, name" do
    result = NodeDevTranslator.to_flex(@node_dev)
    assert_equal @node_dev.id, result[:unid]
    assert_equal @node_dev.uuid, result[:uuid]
    assert_equal "Server Node", result[:name]
  end

  test "to_flex includes nodeDevConfig" do
    result = NodeDevTranslator.to_flex(@node_dev)
    assert_equal({}, result[:nodeDevConfig])
  end

  test "from_flex extracts name" do
    attrs = NodeDevTranslator.from_flex({ "name" => "Node 2" })
    assert_equal "Node 2", attrs[:name]
  end
end
