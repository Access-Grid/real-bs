require "test_helper"

class CredHolderTypeTest < ActiveSupport::TestCase
  test "name is required" do
    cht = CredHolderType.new
    assert_not cht.valid?
    assert_includes cht.errors[:name], "can't be blank"
  end

  test "generates uuid on create" do
    cht = CredHolderType.create!(name: "Staff")
    assert_not_nil cht.uuid
    assert_match(/\A[0-9a-f]{8}-/, cht.uuid)
  end

  test "uuid must be unique" do
    CredHolderType.create!(name: "Staff", uuid: "dup-uuid")
    dup = CredHolderType.new(name: "Visitors", uuid: "dup-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "destroying cred_holder_type destroys associated people" do
    cht = CredHolderType.create!(name: "Staff")
    Person.create!(first_name: "Jane", last_name: "Doe", cred_holder_type: cht)
    assert_difference "Person.count", -1 do
      cht.destroy
    end
  end
end
