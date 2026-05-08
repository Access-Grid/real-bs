require "test_helper"

class CredentialTypeTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    ct = CredentialType.create!(name: "Prox Card")
    assert_not_nil ct.uuid
    assert_match(/\A[0-9a-f]{8}-/, ct.uuid)
  end

  test "does not overwrite existing uuid" do
    ct = CredentialType.create!(name: "Prox Card", uuid: "my-uuid-456")
    assert_equal "my-uuid-456", ct.uuid
  end

  test "uuid must be unique" do
    CredentialType.create!(name: "Type A", uuid: "dup-uuid")
    dup = CredentialType.new(name: "Type B", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    ct = CredentialType.new
    assert_not ct.valid?
    assert_includes ct.errors[:name], "can't be blank"
  end

  test "stores card_pin_template as JSON" do
    tpl = { "credNumPresence" => "REQUIRED", "pinPresence" => "OPTIONAL" }
    ct = CredentialType.create!(name: "Smart Card", card_pin_template: tpl)
    ct.reload
    assert_equal "REQUIRED", ct.card_pin_template["credNumPresence"]
  end

  test "stores priority" do
    ct = CredentialType.create!(name: "High Priority", priority: 10)
    assert_equal 10, ct.reload.priority
  end

  test "destroys dependent credentials" do
    ct = CredentialType.create!(name: "Prox Card")
    Credential.create!(name: "Badge 1", credential_type: ct)
    Credential.create!(name: "Badge 2", credential_type: ct)
    assert_difference "Credential.count", -2 do
      ct.destroy
    end
  end
end
