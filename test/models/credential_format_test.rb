require "test_helper"

class CredentialFormatTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")
    assert_not_nil cf.uuid
    assert_match(/\A[0-9a-f]{8}-/, cf.uuid)
  end

  test "does not overwrite existing uuid" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand", uuid: "my-uuid-123")
    assert_equal "my-uuid-123", cf.uuid
  end

  test "uuid must be unique" do
    CredentialFormat.create!(name: "Format A", uuid: "dup-uuid")
    dup = CredentialFormat.new(name: "Format B", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    cf = CredentialFormat.new
    assert_not cf.valid?
    assert_includes cf.errors[:name], "can't be blank"
  end

  test "stores elements as JSON" do
    elements = [
      { "type" => "FIELD", "name" => "FacilityCode", "bits" => [ 1, 2, 3, 4, 5, 6, 7, 8 ] },
      { "type" => "STATIC", "bitIndex" => 0, "value" => 1 },
      { "type" => "PARITY", "bitIndex" => 25, "parityType" => "ODD", "coverBits" => [ 13, 14, 15 ] }
    ]
    cf = CredentialFormat.create!(name: "26-bit Wiegand", elements: elements)
    cf.reload
    assert_equal 3, cf.elements.length
    assert_equal "FIELD", cf.elements[0]["type"]
    assert_equal "STATIC", cf.elements[1]["type"]
    assert_equal "PARITY", cf.elements[2]["type"]
  end

  test "stores data_format_type, min_bits, max_bits, support_reverse_read" do
    cf = CredentialFormat.create!(
      name: "Custom Format",
      data_format_type: 1,
      min_bits: 26,
      max_bits: 37,
      support_reverse_read: true
    )
    cf.reload
    assert_equal 1, cf.data_format_type
    assert_equal 26, cf.min_bits
    assert_equal 37, cf.max_bits
    assert_equal true, cf.support_reverse_read
  end

  test "has_many data_layouts" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")
    dl = DataLayout.create!(name: "Layout 1", data_format: cf)
    assert_includes cf.data_layouts, dl
  end

  test "nullifies data_layouts on destroy" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")
    dl = DataLayout.create!(name: "Layout 1", data_format: cf)
    cf.destroy
    dl.reload
    assert_nil dl.data_format_id
  end
end
