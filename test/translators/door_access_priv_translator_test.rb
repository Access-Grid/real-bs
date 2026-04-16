require "test_helper"

class DoorAccessPrivTranslatorTest < ActiveSupport::TestCase
  setup do
    @controller_dev = IoController.create!(name: "Main Controller")
    @door = Door.create!(name: "Front Door", physical_parent: @controller_dev)
  end

  test "to_flex maps all fields" do
    ars = AccessRuleSet.create!(name: "Building Access", priv_type: 0, enabled: true)
    ars.door_access_priv_elements.create!(door: @door, sched_restriction_invert: false)

    flex = DoorAccessPrivTranslator.to_flex(ars)

    assert_equal ars.id, flex[:unid]
    assert_equal ars.uuid, flex[:uuid]
    assert_equal "Building Access", flex[:name]
    assert_equal 0, flex[:privType]
    assert_equal true, flex[:enabled]
    assert_equal 1, flex[:elements].length

    elem = flex[:elements][0]
    assert_not_nil elem[:door]
    assert_equal @door.id, elem[:door][:unid]
    assert_equal "Front Door", elem[:door][:name]
    assert_equal "Door", elem[:door][:type]
    assert_not_nil elem[:door][:uuid]
    assert_not_nil elem[:schedRestriction]
    assert_nil elem[:schedRestriction][:sched]
    assert_equal false, elem[:schedRestriction][:invert]
  end

  test "to_flex defaults privType to 0 when nil" do
    ars = AccessRuleSet.create!(name: "Basic")
    flex = DoorAccessPrivTranslator.to_flex(ars)
    assert_equal 0, flex[:privType]
  end

  test "to_flex defaults enabled to true when nil" do
    ars = AccessRuleSet.create!(name: "Basic")
    flex = DoorAccessPrivTranslator.to_flex(ars)
    assert_equal true, flex[:enabled]
  end

  test "to_flex returns empty elements when none exist" do
    ars = AccessRuleSet.create!(name: "No Elements")
    flex = DoorAccessPrivTranslator.to_flex(ars)
    assert_equal [], flex[:elements]
  end

  test "from_flex extracts all fields" do
    json = {
      "name" => "Lobby Access",
      "privType" => 0,
      "enabled" => false
    }

    attrs = DoorAccessPrivTranslator.from_flex(json)

    assert_equal "Lobby Access", attrs[:name]
    assert_equal 0, attrs[:priv_type]
    assert_equal false, attrs[:enabled]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = DoorAccessPrivTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:priv_type)
    assert_not attrs.key?(:enabled)
  end

  test "save_elements creates elements with door by unid" do
    ars = AccessRuleSet.create!(name: "Test")
    elements_json = [
      { "door" => { "unid" => @door.id }, "schedRestriction" => { "invert" => true } }
    ]

    DoorAccessPrivTranslator.save_elements(ars, elements_json)

    assert_equal 1, ars.door_access_priv_elements.count
    el = ars.door_access_priv_elements.first
    assert_equal @door.id, el.door_id
    assert_equal true, el.sched_restriction_invert
  end

  test "save_elements resolves door by uuid" do
    ars = AccessRuleSet.create!(name: "Test")
    elements_json = [
      { "door" => { "uuid" => @door.uuid } }
    ]

    DoorAccessPrivTranslator.save_elements(ars, elements_json)

    assert_equal 1, ars.door_access_priv_elements.count
    assert_equal @door.id, ars.door_access_priv_elements.first.door_id
  end

  test "save_elements replaces existing elements" do
    ars = AccessRuleSet.create!(name: "Test")
    ars.door_access_priv_elements.create!(door: @door)

    door2 = Door.create!(name: "Back Door", physical_parent: @controller_dev)
    elements_json = [
      { "door" => { "unid" => door2.id } }
    ]

    DoorAccessPrivTranslator.save_elements(ars, elements_json)

    assert_equal 1, ars.door_access_priv_elements.count
    assert_equal door2.id, ars.door_access_priv_elements.first.door_id
  end

  test "save_elements skips elements with unresolvable door" do
    ars = AccessRuleSet.create!(name: "Test")
    elements_json = [
      { "door" => { "uuid" => "nonexistent-uuid" } }
    ]

    DoorAccessPrivTranslator.save_elements(ars, elements_json)

    assert_equal 0, ars.door_access_priv_elements.count
  end

  test "save_elements does nothing when not an array" do
    ars = AccessRuleSet.create!(name: "Test")
    ars.door_access_priv_elements.create!(door: @door)

    DoorAccessPrivTranslator.save_elements(ars, nil)

    assert_equal 1, ars.door_access_priv_elements.count
  end
end
