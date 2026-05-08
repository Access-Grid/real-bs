require "test_helper"

class DataLayoutTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    dl = DataLayout.create!(name: "Standard Layout")
    assert_not_nil dl.uuid
    assert_match(/\A[0-9a-f]{8}-/, dl.uuid)
  end

  test "does not overwrite existing uuid" do
    dl = DataLayout.create!(name: "Standard Layout", uuid: "my-uuid-789")
    assert_equal "my-uuid-789", dl.uuid
  end

  test "uuid must be unique" do
    DataLayout.create!(name: "Layout A", uuid: "dup-uuid")
    dup = DataLayout.new(name: "Layout B", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    dl = DataLayout.new
    assert_not dl.valid?
    assert_includes dl.errors[:name], "can't be blank"
  end

  test "belongs_to data_format" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")
    dl = DataLayout.create!(name: "Standard Layout", data_format: cf)
    assert_equal cf, dl.data_format
  end

  test "data_format is optional" do
    dl = DataLayout.create!(name: "Standalone Layout")
    assert_nil dl.data_format
  end

  test "stores priority, enabled, layout_type" do
    dl = DataLayout.create!(
      name: "Priority Layout",
      priority: 5,
      enabled: false,
      layout_type: 0
    )
    dl.reload
    assert_equal 5, dl.priority
    assert_equal false, dl.enabled
    assert_equal 0, dl.layout_type
  end
end
