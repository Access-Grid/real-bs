class CredReaderTranslator < DevTranslatorBase
  def self.to_flex(device)
    config = base_config_to_flex(device)
    cfg = device.dev_config || {}
    config[:commType] = cfg["commType"] unless cfg["commType"].nil?
    config[:tamperType] = cfg["tamperType"] unless cfg["tamperType"].nil?
    config[:ledType] = cfg["ledType"] unless cfg["ledType"].nil?
    config[:serialPortAddress] = cfg["serialPortAddress"] if cfg["serialPortAddress"].present?

    base_dev_fields(device).merge(
      credReaderConfig: config
    )
  end

  def self.from_flex(json)
    attrs = base_from_flex(json)
    config = base_config_from_flex(json, "credReaderConfig")

    cfg = json["credReaderConfig"]
    if cfg.is_a?(Hash)
      config["commType"] = cfg["commType"] if cfg.key?("commType")
      config["tamperType"] = cfg["tamperType"] if cfg.key?("tamperType")
      config["ledType"] = cfg["ledType"] if cfg.key?("ledType")
      config["serialPortAddress"] = cfg["serialPortAddress"] if cfg.key?("serialPortAddress")
    end

    attrs[:dev_config] = config if config.any?
    attrs
  end
end
