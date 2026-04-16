require "test_helper"

class AccessRuleSetTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    ars = AccessRuleSet.create!(name: "Main Priv")
    assert_not_nil ars.uuid
    assert_match(/\A[0-9a-f]{8}-/, ars.uuid)
  end

  test "does not overwrite existing uuid" do
    ars = AccessRuleSet.create!(name: "Main Priv", uuid: "my-uuid-priv")
    assert_equal "my-uuid-priv", ars.uuid
  end

  test "uuid must be unique" do
    AccessRuleSet.create!(name: "Priv A", uuid: "dup-uuid-priv")
    dup = AccessRuleSet.new(name: "Priv B", uuid: "dup-uuid-priv")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    ars = AccessRuleSet.new
    assert_not ars.valid?
    assert_includes ars.errors[:name], "can't be blank"
  end

  test "enabled defaults to true" do
    ars = AccessRuleSet.create!(name: "Default Enabled")
    assert_equal true, ars.enabled
  end

  test "priv_type defaults to 0" do
    ars = AccessRuleSet.create!(name: "Default PrivType")
    assert_equal 0, ars.priv_type
  end

  test "has_many door_access_priv_elements" do
    ars = AccessRuleSet.create!(name: "With Elements")
    controller_dev = IoController.create!(name: "Ctrl")
    door = Door.create!(name: "Front Door", physical_parent: controller_dev)

    ars.door_access_priv_elements.create!(door: door)
    assert_equal 1, ars.door_access_priv_elements.count
    assert_equal door, ars.door_access_priv_elements.first.door
  end

  test "destroying access_rule_set destroys elements" do
    ars = AccessRuleSet.create!(name: "Destroyable")
    controller_dev = IoController.create!(name: "Ctrl")
    door = Door.create!(name: "Door", physical_parent: controller_dev)
    ars.door_access_priv_elements.create!(door: door)

    assert_difference "DoorAccessPrivElement.count", -1 do
      ars.destroy
    end
  end
end
