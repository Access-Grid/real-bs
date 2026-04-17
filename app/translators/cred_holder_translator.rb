class CredHolderTranslator
  def self.obj_ref(record)
    return nil unless record
    name = [record.first_name, record.last_name].compact.join(" ")
    ref = { unid: record.id, name: name, type: FlexTypeNames.for(record) }
    ref[:uuid] = record.uuid if record.respond_to?(:uuid) && record.uuid
    ref
  end

  def self.to_flex(person)
    result = {
      unid: person.id,
      uuid: person.uuid,
      version: person.lock_version,
      tag: person.tag,
      name: [person.first_name, person.last_name].compact.join(" "),
      first: person.first_name,
      last: person.last_name,
      title: person.title,
      enabled: person.enabled,
      credHolderType: CredHolderTypeTranslator.obj_ref(person.cred_holder_type),
      emails: build_emails(person),
      phones: build_phones(person),
      customData: build_custom_data(person)
    }
    result
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:lock_version] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:first_name] = json["first"] if json.key?("first")
    attrs[:last_name] = json["last"] if json.key?("last")
    attrs[:title] = json["title"] if json.key?("title")
    attrs[:enabled] = json["enabled"] if json.key?("enabled")

    if json.key?("credHolderType")
      cht = json["credHolderType"]
      if cht.is_a?(Hash) && cht["unid"]
        attrs[:cred_holder_type_id] = cht["unid"]
      elsif cht.is_a?(Hash) && cht["uuid"]
        cht_record = CredHolderType.find_by(uuid: cht["uuid"])
        attrs[:cred_holder_type_id] = cht_record&.id
      elsif cht.nil?
        attrs[:cred_holder_type_id] = nil
      end
    end

    # emails -- store first HOME email as email column
    if json.key?("emails")
      emails = json["emails"]
      if emails.is_a?(Array) && emails.any?
        home_email = emails.find { |e| e["type"].nil? || e["type"] == 0 }
        home_email ||= emails.first
        attrs[:email] = home_email["emailAddress"] if home_email
      else
        attrs[:email] = nil
      end
    end

    # phones -- store first MOBILE phone as phone_number column
    if json.key?("phones")
      phones = json["phones"]
      if phones.is_a?(Array) && phones.any?
        mobile = phones.find { |p| p["type"].nil? || p["type"] == 2 }
        mobile ||= phones.first
        attrs[:phone_number] = mobile["phoneNumber"] if mobile
      else
        attrs[:phone_number] = nil
      end
    end

    # customData -- map customText0-7 to custom_text_0-7 columns
    if json.key?("customData")
      cd = json["customData"]
      if cd.is_a?(Hash)
        8.times do |i|
          key = "customText#{i}"
          attrs[:"custom_text_#{i}"] = cd[key] if cd.key?(key)
        end
      end
    end

    attrs
  end

  def self.build_emails(person)
    return [] unless person.email.present?
    [{ unid: 1, type: 0, emailAddress: person.email }]
  end

  def self.build_phones(person)
    return [] unless person.phone_number.present?
    [{ unid: 1, type: 2, phoneNumber: person.phone_number }]
  end

  def self.build_custom_data(person)
    data = {}
    8.times do |i|
      val = person.send(:"custom_text_#{i}")
      data["customText#{i}"] = val if val.present?
    end
    data.empty? ? nil : data
  end

  private_class_method :build_emails, :build_phones, :build_custom_data
end
