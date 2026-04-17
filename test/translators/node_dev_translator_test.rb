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

  test "to_flex includes empty nodeDevConfig when no dev_config" do
    result = NodeDevTranslator.to_flex(@node_dev)
    assert_equal({}, result[:nodeDevConfig])
  end

  test "from_flex extracts name" do
    attrs = NodeDevTranslator.from_flex({ "name" => "Node 2" })
    assert_equal "Node 2", attrs[:name]
  end

  # -- NodeDevConfig --

  test "to_flex returns nodeDevConfig with base fields" do
    @node_dev.update!(dev_config: { "username" => "node_admin", "password" => "np" })
    result = NodeDevTranslator.to_flex(@node_dev)
    assert_equal "node_admin", result[:nodeDevConfig][:username]
    assert_equal "np", result[:nodeDevConfig][:password]
  end

  test "from_flex extracts nodeDevConfig into dev_config" do
    attrs = NodeDevTranslator.from_flex({
      "name" => "Node",
      "nodeDevConfig" => { "username" => "admin", "devInitiatesConnection" => true }
    })
    assert_equal "admin", attrs[:dev_config]["username"]
    assert_equal true, attrs[:dev_config]["devInitiatesConnection"]
  end

  test "from_flex without nodeDevConfig does not set dev_config" do
    attrs = NodeDevTranslator.from_flex({ "name" => "Node" })
    assert_nil attrs[:dev_config]
  end
end
