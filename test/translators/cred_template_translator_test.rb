require "test_helper"

class CredTemplateTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    ct = CredentialType.create!(
      name: "Smart Card",
      priority: 5,
      card_pin_template: { "credNumPresence" => "REQUIRED", "pinPresence" => "NONE" }
    )

    flex = CredTemplateTranslator.to_flex(ct)

    assert_equal ct.id, flex[:unid]
    assert_equal ct.uuid, flex[:uuid]
    assert_equal "Smart Card", flex[:name]
    assert_equal 5, flex[:priority]
    assert_equal({ "credNumPresence" => "REQUIRED", "pinPresence" => "NONE" }, flex[:cardPinTemplate])
  end

  test "to_flex defaults priority to 0 when nil" do
    ct = CredentialType.create!(name: "Basic")
    flex = CredTemplateTranslator.to_flex(ct)
    assert_equal 0, flex[:priority]
  end

  test "to_flex defaults cardPinTemplate to empty hash when nil" do
    ct = CredentialType.create!(name: "Basic")
    flex = CredTemplateTranslator.to_flex(ct)
    assert_equal({}, flex[:cardPinTemplate])
  end

  test "from_flex extracts all fields" do
    json = {
      "name" => "Prox Card",
      "priority" => 3,
      "cardPinTemplate" => { "credNumPresence" => "OPTIONAL" }
    }

    attrs = CredTemplateTranslator.from_flex(json)

    assert_equal "Prox Card", attrs[:name]
    assert_equal 3, attrs[:priority]
    assert_equal({ "credNumPresence" => "OPTIONAL" }, attrs[:card_pin_template])
  end

  test "from_flex only includes present keys" do
    json = { "name" => "Minimal" }
    attrs = CredTemplateTranslator.from_flex(json)
    assert_equal({ name: "Minimal" }, attrs)
    assert_not attrs.key?(:priority)
    assert_not attrs.key?(:card_pin_template)
  end
end
