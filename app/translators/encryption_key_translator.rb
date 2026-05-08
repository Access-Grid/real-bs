class EncryptionKeyTranslator
  def self.to_flex(ek)
    {
      unid: ek.id,
      uuid: ek.uuid,
      version: ek.lock_version,
      tag: ek.tag,
      algorithm: ek.algorithm,
      size: ek.size,
      keyIdentifier: ek.key_identifier,
      bytes: ek.bytes
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:lock_version] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:algorithm] = json["algorithm"] if json.key?("algorithm")
    attrs[:size] = json["size"] if json.key?("size")
    attrs[:key_identifier] = json["keyIdentifier"] if json.key?("keyIdentifier")
    attrs[:bytes] = json["bytes"] if json.key?("bytes")
    attrs
  end
end
