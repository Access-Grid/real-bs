class ControllerTranslator < DevTranslatorBase
  def self.to_flex(device)
    base_dev_fields(device).merge(
      controllerConfig: base_config_to_flex(device)
    )
  end

  def self.from_flex(json)
    attrs = base_from_flex(json)
    config = base_config_from_flex(json, "controllerConfig")
    attrs[:dev_config] = config if config.any?
    attrs
  end
end
