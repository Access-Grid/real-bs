require "test_helper"

class CredentialTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    cred = Credential.create!(name: "Badge 1")
    assert_not_nil cred.uuid
    assert_match(/\A[0-9a-f]{8}-/, cred.uuid)
  end

  test "does not overwrite existing uuid" do
    cred = Credential.create!(name: "Badge 1", uuid: "custom-uuid-123")
    assert_equal "custom-uuid-123", cred.uuid
  end

  test "uuid must be unique" do
    Credential.create!(name: "Badge 1", uuid: "dup-uuid")
    dup = Credential.new(name: "Badge 2", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "name is required" do
    cred = Credential.new
    assert_not cred.valid?
    assert_includes cred.errors[:name], "can't be blank"
  end

  test "person is optional" do
    cred = Credential.create!(name: "Badge No Person")
    assert_nil cred.person_id
  end

  test "credential_type is optional" do
    cred = Credential.create!(name: "Badge No Template")
    assert_nil cred.credential_type_id
  end

  test "can associate with person" do
    group = Group.create!(name: "Staff")
    person = Person.create!(first_name: "John", last_name: "Doe", group: group)
    cred = Credential.create!(name: "John Badge", person: person)
    assert_equal person.id, cred.person_id
  end

  test "can associate with credential_type" do
    ct = CredentialType.create!(name: "Prox Card")
    cred = Credential.create!(name: "Badge 1", credential_type: ct)
    assert_equal ct.id, cred.credential_type_id
  end

  test "enabled defaults to true" do
    cred = Credential.create!(name: "Badge")
    assert_equal true, cred.enabled
  end

  test "stores card_pin as JSON" do
    pin_data = { "credNum" => "12345", "facilityCode" => "100", "pin" => "9999" }
    cred = Credential.create!(name: "Badge", card_pin: pin_data)
    cred.reload
    assert_equal "12345", cred.card_pin["credNum"]
    assert_equal "100", cred.card_pin["facilityCode"]
  end

  test "effective and expires are stored" do
    eff = Time.utc(2026, 1, 1)
    exp = Time.utc(2027, 1, 1)
    cred = Credential.create!(name: "Badge", effective: eff, expires: exp)
    cred.reload
    assert_in_delta eff, cred.effective, 1
    assert_in_delta exp, cred.expires, 1
  end
end
