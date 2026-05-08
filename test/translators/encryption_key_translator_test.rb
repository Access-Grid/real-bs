require "test_helper"

class EncryptionKeyTranslatorTest < ActiveSupport::TestCase
  test "to_flex maps all fields" do
    ek = EncryptionKey.create!(
      algorithm: "RSA",
      size: 2048,
      key_identifier: "master-key",
      bytes: "base64encodeddata"
    )

    flex = EncryptionKeyTranslator.to_flex(ek)

    assert_equal ek.id, flex[:unid]
    assert_equal ek.uuid, flex[:uuid]
    assert_equal "RSA", flex[:algorithm]
    assert_equal 2048, flex[:size]
    assert_equal "master-key", flex[:keyIdentifier]
    assert_equal "base64encodeddata", flex[:bytes]
  end

  test "from_flex extracts all fields" do
    json = {
      "algorithm" => "AES",
      "size" => 256,
      "keyIdentifier" => "session-key",
      "bytes" => "aes256bytes"
    }

    attrs = EncryptionKeyTranslator.from_flex(json)

    assert_equal "AES", attrs[:algorithm]
    assert_equal 256, attrs[:size]
    assert_equal "session-key", attrs[:key_identifier]
    assert_equal "aes256bytes", attrs[:bytes]
  end

  test "from_flex only includes present keys" do
    json = { "algorithm" => "RSA" }
    attrs = EncryptionKeyTranslator.from_flex(json)
    assert_equal({ algorithm: "RSA" }, attrs)
    assert_not attrs.key?(:size)
    assert_not attrs.key?(:key_identifier)
  end
end
