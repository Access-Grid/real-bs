require "test_helper"

class BasicDataLayoutTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")
    dl = DataLayout.create!(
      name: "Standard Layout",
      layout_type: 0,
      priority: 5,
      enabled: true,
      data_format: cf
    )

    flex = BasicDataLayoutTranslator.to_flex(dl)

    assert_equal dl.id, flex[:unid]
    assert_equal dl.uuid, flex[:uuid]
    assert_equal "Standard Layout", flex[:name]
    assert_equal 0, flex[:layoutType]
    assert_equal 5, flex[:priority]
    assert_equal true, flex[:enabled]
    assert_not_nil flex[:dataFormat]
    assert_equal cf.id, flex[:dataFormat][:unid]
    assert_equal cf.uuid, flex[:dataFormat][:uuid]
    assert_equal "26-bit Wiegand", flex[:dataFormat][:name]
  end

  test "to_flex defaults priority to 0 when nil" do
    dl = DataLayout.create!(name: "Basic")
    flex = BasicDataLayoutTranslator.to_flex(dl)
    assert_equal 0, flex[:priority]
  end

  test "to_flex defaults enabled to true when nil" do
    dl = DataLayout.create!(name: "Basic")
    flex = BasicDataLayoutTranslator.to_flex(dl)
    assert_equal true, flex[:enabled]
  end

  test "to_flex returns nil dataFormat when not set" do
    dl = DataLayout.create!(name: "No Format")
    flex = BasicDataLayoutTranslator.to_flex(dl)
    assert_nil flex[:dataFormat]
  end

  test "from_flex extracts all fields" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")

    json = {
      "name" => "Custom Layout",
      "layoutType" => 0,
      "priority" => 3,
      "enabled" => false,
      "dataFormat" => { "unid" => cf.id }
    }

    attrs = BasicDataLayoutTranslator.from_flex(json)

    assert_equal "Custom Layout", attrs[:name]
    assert_equal 0, attrs[:layout_type]
    assert_equal 3, attrs[:priority]
    assert_equal false, attrs[:enabled]
    assert_equal cf.id, attrs[:data_format_id]
  end

  test "from_flex resolves dataFormat by uuid" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand")

    json = {
      "name" => "UUID Layout",
      "dataFormat" => { "uuid" => cf.uuid }
    }

    attrs = BasicDataLayoutTranslator.from_flex(json)
    assert_equal cf.id, attrs[:data_format_id]
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = BasicDataLayoutTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:priority)
    assert_not attrs.key?(:data_format_id)
  end
end
