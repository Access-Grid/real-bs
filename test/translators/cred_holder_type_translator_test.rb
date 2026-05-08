require "test_helper"

class CredHolderTypeTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    cht = CredHolderType.create!(name: "Staff", tag: "t1")
    flex = CredHolderTypeTranslator.to_flex(cht)

    assert_equal cht.id, flex[:unid]
    assert_equal cht.uuid, flex[:uuid]
    assert_equal 0, flex[:version]
    assert_equal "t1", flex[:tag]
    assert_equal "Staff", flex[:name]
  end

  test "from_flex extracts basic fields" do
    json = { "name" => "Visitors", "tag" => "v1", "version" => 2 }
    attrs = CredHolderTypeTranslator.from_flex(json)

    assert_equal "Visitors", attrs[:name]
    assert_equal "v1", attrs[:tag]
    assert_equal 2, attrs[:lock_version]
  end

  test "obj_ref returns correct structure" do
    cht = CredHolderType.create!(name: "Staff")
    ref = CredHolderTypeTranslator.obj_ref(cht)

    assert_equal cht.id, ref[:unid]
    assert_equal "Staff", ref[:name]
    assert_equal "CredHolderType", ref[:type]
    assert_equal cht.uuid, ref[:uuid]
  end

  test "obj_ref returns nil for nil record" do
    assert_nil CredHolderTypeTranslator.obj_ref(nil)
  end
end
