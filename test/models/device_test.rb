require "test_helper"

class DeviceTest < ActiveSupport::TestCase
  setup do
    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
  end

  test "IoController has devType 1" do
    c = IoController.create!(name: "Panel", sector: @sector)
    assert_equal 1, c.dev_type
    assert_equal "IoController", c.type
  end

  test "Sensor has devType 2" do
    s = Sensor.create!(name: "Contact", sector: @sector)
    assert_equal 2, s.dev_type
  end

  test "CredReader has devType 4" do
    r = CredReader.create!(name: "Reader", sector: @sector)
    assert_equal 4, r.dev_type
  end

  test "Door has devType 5" do
    d = Door.create!(name: "Door", sector: @sector)
    assert_equal 5, d.dev_type
  end

  test "all device types share one ID space" do
    c = IoController.create!(name: "Panel", sector: @sector)
    d = Door.create!(name: "Door", sector: @sector)
    r = CredReader.create!(name: "Reader", sector: @sector)
    s = Sensor.create!(name: "Contact", sector: @sector)

    ids = [ c.id, d.id, r.id, s.id ]
    assert_equal ids.uniq.length, 4, "All device IDs should be unique across types"
  end

  test "Device.find returns correct subclass" do
    c = IoController.create!(name: "Panel", sector: @sector)
    found = Device.find(c.id)
    assert_instance_of IoController, found
  end

  test "Device.all returns all device types" do
    IoController.create!(name: "Panel", sector: @sector)
    Door.create!(name: "Door", sector: @sector)
    all = Device.all.to_a
    assert all.length >= 2
    types = all.map(&:class).uniq
    assert_includes types, IoController
    assert_includes types, Door
  end

  test "physical_parent and logical_parent hierarchy" do
    controller = IoController.create!(name: "Panel", sector: @sector)
    door = Door.create!(name: "Door", sector: @sector, logical_parent: controller)
    reader = CredReader.create!(name: "Reader", sector: @sector, physical_parent: controller, logical_parent: door)

    assert_equal controller, door.logical_parent
    assert_includes controller.logical_children, door
    assert_equal controller, reader.physical_parent
    assert_equal door, reader.logical_parent
    assert_includes door.logical_children, reader
    assert_includes controller.physical_children, reader
  end

  test "generates uuid on create" do
    c = IoController.create!(name: "Panel", sector: @sector)
    assert_not_nil c.uuid
    assert_match(/\A[0-9a-f-]{36}\z/, c.uuid)
  end

  test "validates name presence" do
    d = Device.new(type: "IoController", sector: @sector)
    assert_not d.valid?
    assert_includes d.errors[:name], "can't be blank"
  end
end
