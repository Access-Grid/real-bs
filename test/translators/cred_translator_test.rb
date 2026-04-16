require "test_helper"

class CredTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    ct = CredentialType.create!(name: "Prox Card")
    group = Group.create!(name: "Staff")
    person = Person.create!(first_name: "Jane", last_name: "Doe", group: group)
    cred = Credential.create!(
      name: "Jane Badge",
      enabled: true,
      effective: Time.utc(2026, 1, 1),
      expires: Time.utc(2027, 1, 1),
      card_pin: { "credNum" => "555", "facilityCode" => "42" },
      credential_type: ct,
      person: person
    )

    flex = CredTranslator.to_flex(cred)

    assert_equal cred.id, flex[:unid]
    assert_equal cred.uuid, flex[:uuid]
    assert_equal "Jane Badge", flex[:name]
    assert_equal true, flex[:enabled]
    assert_equal "2026-01-01T00:00:00Z", flex[:effective]
    assert_equal "2027-01-01T00:00:00Z", flex[:expires]
    assert_equal({ "credNum" => "555", "facilityCode" => "42" }, flex[:cardPin])
    assert_equal [], flex[:privBindings]

    # credTemplate ObjRef
    assert_equal ct.id, flex[:credTemplate][:unid]
    assert_equal ct.name, flex[:credTemplate][:name]
    assert_equal ct.uuid, flex[:credTemplate][:uuid]

    # credHolder ObjRef
    assert_equal person.id, flex[:credHolder][:unid]
  end

  test "to_flex handles nil associations" do
    cred = Credential.create!(name: "Orphan Badge")
    flex = CredTranslator.to_flex(cred)

    assert_nil flex[:credTemplate]
    assert_nil flex[:credHolder]
    assert_equal({}, flex[:cardPin])
  end

  test "to_flex handles nil effective/expires" do
    cred = Credential.create!(name: "No Dates")
    flex = CredTranslator.to_flex(cred)

    assert_nil flex[:effective]
    assert_nil flex[:expires]
  end

  test "from_flex extracts basic fields" do
    json = {
      "name" => "New Badge",
      "enabled" => false,
      "effective" => "2026-06-01T00:00:00Z",
      "expires" => "2027-06-01T00:00:00Z",
      "cardPin" => { "credNum" => "999" }
    }

    attrs = CredTranslator.from_flex(json)

    assert_equal "New Badge", attrs[:name]
    assert_equal false, attrs[:enabled]
    assert_equal "2026-06-01T00:00:00Z", attrs[:effective]
    assert_equal "2027-06-01T00:00:00Z", attrs[:expires]
    assert_equal({ "credNum" => "999" }, attrs[:card_pin])
  end

  test "from_flex resolves credTemplate by unid" do
    ct = CredentialType.create!(name: "Smart Card")
    json = { "name" => "Badge", "credTemplate" => { "unid" => ct.id } }
    attrs = CredTranslator.from_flex(json)
    assert_equal ct.id, attrs[:credential_type_id]
  end

  test "from_flex resolves credTemplate by uuid" do
    ct = CredentialType.create!(name: "Smart Card")
    json = { "name" => "Badge", "credTemplate" => { "uuid" => ct.uuid } }
    attrs = CredTranslator.from_flex(json)
    assert_equal ct.id, attrs[:credential_type_id]
  end

  test "from_flex resolves credHolder by unid" do
    group = Group.create!(name: "Staff")
    person = Person.create!(first_name: "Bob", last_name: "Smith", group: group)
    json = { "name" => "Badge", "credHolder" => { "unid" => person.id } }
    attrs = CredTranslator.from_flex(json)
    assert_equal person.id, attrs[:person_id]
  end

  test "from_flex ignores unknown keys" do
    json = { "name" => "Badge", "unknownField" => "ignored" }
    attrs = CredTranslator.from_flex(json)
    assert_equal({ name: "Badge" }, attrs)
  end
end
