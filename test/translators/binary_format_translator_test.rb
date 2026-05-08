require "test_helper"

class BinaryFormatTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    cf = CredentialFormat.create!(
      name: "26-bit Wiegand",
      data_format_type: 1,
      min_bits: 26,
      max_bits: 26,
      support_reverse_read: false,
      elements: [
        { "type" => "STATIC", "bitIndex" => 0, "value" => 1 },
        { "type" => "PARITY", "bitIndex" => 25, "parityType" => "ODD", "coverBits" => [ 13, 14 ] },
        { "type" => "FIELD", "name" => "FacilityCode", "bits" => [ 1, 2, 3, 4 ] }
      ]
    )

    flex = BinaryFormatTranslator.to_flex(cf)

    assert_equal cf.id, flex[:unid]
    assert_equal cf.uuid, flex[:uuid]
    assert_equal "26-bit Wiegand", flex[:name]
    assert_equal 1, flex[:dataFormatType]
    assert_equal 26, flex[:minBits]
    assert_equal 26, flex[:maxBits]
    assert_equal false, flex[:supportReverseRead]
    assert_equal 3, flex[:elements].length
    assert_equal "STATIC", flex[:elements][0]["type"]
    assert_equal "PARITY", flex[:elements][1]["type"]
    assert_equal "FIELD", flex[:elements][2]["type"]
  end

  test "to_flex defaults elements to empty array when nil" do
    cf = CredentialFormat.create!(name: "Empty Format")
    flex = BinaryFormatTranslator.to_flex(cf)
    assert_equal [], flex[:elements]
  end

  test "to_flex defaults dataFormatType to 1 when nil" do
    cf = CredentialFormat.create!(name: "Default Type")
    flex = BinaryFormatTranslator.to_flex(cf)
    assert_equal 1, flex[:dataFormatType]
  end

  test "to_flex defaults supportReverseRead to false when nil" do
    cf = CredentialFormat.create!(name: "Default Reverse")
    flex = BinaryFormatTranslator.to_flex(cf)
    assert_equal false, flex[:supportReverseRead]
  end

  test "from_flex extracts all fields" do
    json = {
      "name" => "37-bit HID",
      "dataFormatType" => 1,
      "minBits" => 37,
      "maxBits" => 37,
      "supportReverseRead" => true,
      "elements" => [
        { "type" => "FIELD", "name" => "CardNumber", "bits" => [ 1, 2, 3 ] }
      ]
    }

    attrs = BinaryFormatTranslator.from_flex(json)

    assert_equal "37-bit HID", attrs[:name]
    assert_equal 1, attrs[:data_format_type]
    assert_equal 37, attrs[:min_bits]
    assert_equal 37, attrs[:max_bits]
    assert_equal true, attrs[:support_reverse_read]
    assert_equal 1, attrs[:elements].length
    assert_equal "FIELD", attrs[:elements][0]["type"]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = BinaryFormatTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:min_bits)
    assert_not attrs.key?(:elements)
  end
end
