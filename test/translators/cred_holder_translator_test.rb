require "test_helper"

class CredHolderTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    cht = CredHolderType.create!(name: "Staff")
    person = Person.create!(
      first_name: "Jane", last_name: "Doe", title: "Ms.",
      email: "jane@example.com", phone_number: "555-1234",
      enabled: true, tag: "t1", cred_holder_type: cht,
      custom_text_0: "Badge A", custom_text_3: "Dept X"
    )

    flex = CredHolderTranslator.to_flex(person)

    assert_equal person.id, flex[:unid]
    assert_equal person.uuid, flex[:uuid]
    assert_equal 0, flex[:version]
    assert_equal "t1", flex[:tag]
    assert_equal "Jane Doe", flex[:name]
    assert_equal "Jane", flex[:first]
    assert_equal "Doe", flex[:last]
    assert_equal "Ms.", flex[:title]
    assert_equal true, flex[:enabled]

    # credHolderType ObjRef
    assert_equal cht.id, flex[:credHolderType][:unid]
    assert_equal "Staff", flex[:credHolderType][:name]

    # emails
    assert_equal 1, flex[:emails].length
    assert_equal "jane@example.com", flex[:emails][0][:emailAddress]
    assert_equal 0, flex[:emails][0][:type]

    # phones
    assert_equal 1, flex[:phones].length
    assert_equal "555-1234", flex[:phones][0][:phoneNumber]
    assert_equal 2, flex[:phones][0][:type]

    # customData
    assert_equal "Badge A", flex[:customData]["customText0"]
    assert_equal "Dept X", flex[:customData]["customText3"]
    assert_nil flex[:customData]["customText1"]
  end

  test "to_flex handles nil associations" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    flex = CredHolderTranslator.to_flex(person)

    assert_nil flex[:credHolderType]
    assert_equal [], flex[:emails]
    assert_equal [], flex[:phones]
    assert_nil flex[:customData]
  end

  test "from_flex extracts basic fields" do
    json = {
      "first" => "Bob", "last" => "Smith", "title" => "Mr.",
      "enabled" => false, "tag" => "t2", "version" => 3
    }
    attrs = CredHolderTranslator.from_flex(json)

    assert_equal "Bob", attrs[:first_name]
    assert_equal "Smith", attrs[:last_name]
    assert_equal "Mr.", attrs[:title]
    assert_equal false, attrs[:enabled]
    assert_equal "t2", attrs[:tag]
    assert_equal 3, attrs[:lock_version]
  end

  test "from_flex resolves credHolderType by unid" do
    cht = CredHolderType.create!(name: "Staff")
    json = { "first" => "Jane", "last" => "Doe", "credHolderType" => { "unid" => cht.id } }
    attrs = CredHolderTranslator.from_flex(json)
    assert_equal cht.id, attrs[:cred_holder_type_id]
  end

  test "from_flex resolves credHolderType by uuid" do
    cht = CredHolderType.create!(name: "Staff")
    json = { "first" => "Jane", "last" => "Doe", "credHolderType" => { "uuid" => cht.uuid } }
    attrs = CredHolderTranslator.from_flex(json)
    assert_equal cht.id, attrs[:cred_holder_type_id]
  end

  test "from_flex clears credHolderType when null" do
    json = { "first" => "Jane", "last" => "Doe", "credHolderType" => nil }
    attrs = CredHolderTranslator.from_flex(json)
    assert_nil attrs[:cred_holder_type_id]
  end

  test "from_flex extracts email from emails array" do
    json = {
      "first" => "Jane", "last" => "Doe",
      "emails" => [{ "type" => 0, "emailAddress" => "jane@example.com" }]
    }
    attrs = CredHolderTranslator.from_flex(json)
    assert_equal "jane@example.com", attrs[:email]
  end

  test "from_flex extracts phone from phones array" do
    json = {
      "first" => "Jane", "last" => "Doe",
      "phones" => [{ "type" => 2, "phoneNumber" => "555-1234" }]
    }
    attrs = CredHolderTranslator.from_flex(json)
    assert_equal "555-1234", attrs[:phone_number]
  end

  test "from_flex extracts customData fields" do
    json = {
      "first" => "Jane", "last" => "Doe",
      "customData" => { "customText0" => "Hello", "customText5" => "World" }
    }
    attrs = CredHolderTranslator.from_flex(json)
    assert_equal "Hello", attrs[:custom_text_0]
    assert_equal "World", attrs[:custom_text_5]
    assert_nil attrs[:custom_text_1]
  end

  test "obj_ref returns correct structure" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    ref = CredHolderTranslator.obj_ref(person)

    assert_equal person.id, ref[:unid]
    assert_equal "Jane Doe", ref[:name]
    assert_equal "CredHolder", ref[:type]
    assert_equal person.uuid, ref[:uuid]
  end

  test "obj_ref returns nil for nil record" do
    assert_nil CredHolderTranslator.obj_ref(nil)
  end
end
