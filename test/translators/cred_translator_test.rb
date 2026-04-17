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

  test "to_flex maps privBindings with priv ObjRef" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "All Doors")
    sched = Schedule.create!(name: "Business Hours")
    cred.cred_priv_bindings.create!(access_rule_set: ars, schedule: sched, sched_restriction_invert: true)

    flex = CredTranslator.to_flex(cred)

    assert_equal 1, flex[:privBindings].length
    pb = flex[:privBindings][0]
    assert_not_nil pb[:unid]
    assert_equal ars.id, pb[:priv][:unid]
    assert_equal "All Doors", pb[:priv][:name]
    assert_equal sched.id, pb[:schedRestriction][:sched][:unid]
    assert_equal "Business Hours", pb[:schedRestriction][:sched][:name]
    assert_equal true, pb[:schedRestriction][:invert]
    assert_nil pb[:devAsDoorAccessPriv]
  end

  test "to_flex maps privBindings with devAsDoorAccessPriv" do
    cred = Credential.create!(name: "Badge")
    door = Door.create!(name: "Front Door")
    cred.cred_priv_bindings.create!(dev_as_door_access_priv_unid: door.id)

    flex = CredTranslator.to_flex(cred)

    pb = flex[:privBindings][0]
    assert_nil pb[:priv]
    assert_equal door.id, pb[:devAsDoorAccessPriv][:unid]
    assert_equal "Front Door", pb[:devAsDoorAccessPriv][:name]
  end

  test "to_flex returns empty privBindings when none exist" do
    cred = Credential.create!(name: "Badge")
    flex = CredTranslator.to_flex(cred)
    assert_equal [], flex[:privBindings]
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

  test "to_flex maps doorAccessModifiers" do
    cred = Credential.create!(name: "ADA Badge", door_access_modifiers: { "extDoorTime" => true })
    flex = CredTranslator.to_flex(cred)
    assert_equal({ "extDoorTime" => true }, flex[:doorAccessModifiers])
  end

  test "to_flex returns empty doorAccessModifiers when nil" do
    cred = Credential.create!(name: "No DAM")
    flex = CredTranslator.to_flex(cred)
    assert_equal({}, flex[:doorAccessModifiers])
  end

  test "from_flex extracts doorAccessModifiers" do
    attrs = CredTranslator.from_flex({
      "name" => "Badge",
      "doorAccessModifiers" => { "extDoorTime" => true }
    })
    assert_equal({ "extDoorTime" => true }, attrs[:door_access_modifiers])
  end

  test "from_flex ignores unknown keys" do
    json = { "name" => "Badge", "unknownField" => "ignored" }
    attrs = CredTranslator.from_flex(json)
    assert_equal({ name: "Badge" }, attrs)
  end

  # -- save_priv_bindings --

  test "save_priv_bindings creates bindings with priv by unid" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "ARS")
    sched = Schedule.create!(name: "Sched")

    bindings = [
      {
        "priv" => { "unid" => ars.id },
        "schedRestriction" => { "sched" => { "unid" => sched.id }, "invert" => true }
      }
    ]
    CredTranslator.save_priv_bindings(cred, bindings)

    assert_equal 1, cred.cred_priv_bindings.count
    b = cred.cred_priv_bindings.first
    assert_equal ars.id, b.access_rule_set_id
    assert_equal sched.id, b.schedule_id
    assert_equal true, b.sched_restriction_invert
  end

  test "save_priv_bindings resolves priv by uuid" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "ARS")

    bindings = [{ "priv" => { "uuid" => ars.uuid } }]
    CredTranslator.save_priv_bindings(cred, bindings)

    assert_equal ars.id, cred.cred_priv_bindings.first.access_rule_set_id
  end

  test "save_priv_bindings resolves schedule by uuid" do
    cred = Credential.create!(name: "Badge")
    sched = Schedule.create!(name: "Sched")

    bindings = [{ "schedRestriction" => { "sched" => { "uuid" => sched.uuid } } }]
    CredTranslator.save_priv_bindings(cred, bindings)

    assert_equal sched.id, cred.cred_priv_bindings.first.schedule_id
  end

  test "save_priv_bindings with devAsDoorAccessPriv" do
    cred = Credential.create!(name: "Badge")
    door = Door.create!(name: "Front Door")

    bindings = [{ "devAsDoorAccessPriv" => { "unid" => door.id } }]
    CredTranslator.save_priv_bindings(cred, bindings)

    assert_equal door.id, cred.cred_priv_bindings.first.dev_as_door_access_priv_unid
  end

  test "save_priv_bindings replaces existing bindings" do
    cred = Credential.create!(name: "Badge")
    ars1 = AccessRuleSet.create!(name: "ARS 1")
    ars2 = AccessRuleSet.create!(name: "ARS 2")
    cred.cred_priv_bindings.create!(access_rule_set: ars1)

    bindings = [{ "priv" => { "unid" => ars2.id } }]
    CredTranslator.save_priv_bindings(cred, bindings)

    assert_equal 1, cred.cred_priv_bindings.count
    assert_equal ars2.id, cred.cred_priv_bindings.first.access_rule_set_id
  end

  test "save_priv_bindings does nothing when not an array" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "ARS")
    cred.cred_priv_bindings.create!(access_rule_set: ars)

    CredTranslator.save_priv_bindings(cred, nil)

    assert_equal 1, cred.cred_priv_bindings.count
  end
end
