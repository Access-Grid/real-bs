class SensorTranslator < DevTranslatorBase
  def self.to_flex(device)
    config = base_config_to_flex(device)
    cfg = device.dev_config || {}
    config[:invert] = cfg["invert"] unless cfg["invert"].nil?

    base_dev_fields(device).merge(
      sensorConfig: config
    )
  end

  def self.from_flex(json)
    attrs = base_from_flex(json)
    config = base_config_from_flex(json, "sensorConfig")

    cfg = json["sensorConfig"]
    if cfg.is_a?(Hash)
      config["invert"] = cfg["invert"] if cfg.key?("invert")
    end

    attrs[:dev_config] = config if config.any?
    attrs
  end
end
