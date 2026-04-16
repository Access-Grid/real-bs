require "test_helper"

class EncryptionKeyTest < ActiveSupport::TestCase
  test "generates uuid on create" do
    ek = EncryptionKey.create!
    assert_not_nil ek.uuid
    assert_match(/\A[0-9a-f]{8}-/, ek.uuid)
  end

  test "does not overwrite existing uuid" do
    ek = EncryptionKey.create!(uuid: "my-ek-uuid")
    assert_equal "my-ek-uuid", ek.uuid
  end

  test "uuid must be unique" do
    EncryptionKey.create!(uuid: "dup-ek-uuid")
    dup = EncryptionKey.new(uuid: "dup-ek-uuid")
    assert_not dup.valid?
    assert_includes dup.errors[:uuid], "has already been taken"
  end

  test "stores all fields" do
    ek = EncryptionKey.create!(
      algorithm: "RSA",
      size: 2048,
      key_identifier: "master-key",
      bytes: "base64data"
    )
    ek.reload
    assert_equal "RSA", ek.algorithm
    assert_equal 2048, ek.size
    assert_equal "master-key", ek.key_identifier
    assert_equal "base64data", ek.bytes
  end
end
