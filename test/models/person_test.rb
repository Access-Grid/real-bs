require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "first_name is required" do
    person = Person.new(last_name: "Doe")
    assert_not person.valid?
    assert_includes person.errors[:first_name], "can't be blank"
  end

  test "last_name is required" do
    person = Person.new(first_name: "Jane")
    assert_not person.valid?
    assert_includes person.errors[:last_name], "can't be blank"
  end

  test "generates uuid on create" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    assert_not_nil person.uuid
    assert_match(/\A[0-9a-f]{8}-/, person.uuid)
  end

  test "uuid must be unique" do
    Person.create!(first_name: "Jane", last_name: "Doe", uuid: "dup-uuid")
    dup = Person.new(first_name: "John", last_name: "Doe", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "cred_holder_type is optional" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    assert_nil person.cred_holder_type_id
  end

  test "can associate with cred_holder_type" do
    cht = CredHolderType.create!(name: "Staff")
    person = Person.create!(first_name: "Jane", last_name: "Doe", cred_holder_type: cht)
    assert_equal cht.id, person.cred_holder_type_id
  end

  test "enabled defaults to true" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    assert_equal true, person.enabled
  end

  test "stores custom_text fields" do
    person = Person.create!(first_name: "Jane", last_name: "Doe",
      custom_text_0: "Badge A", custom_text_3: "Dept X")
    person.reload
    assert_equal "Badge A", person.custom_text_0
    assert_nil person.custom_text_1
    assert_equal "Dept X", person.custom_text_3
  end

  test "destroying person destroys associated credentials" do
    person = Person.create!(first_name: "Jane", last_name: "Doe")
    Credential.create!(name: "Badge 1", person: person)
    assert_difference "Credential.count", -1 do
      person.destroy
    end
  end
end
