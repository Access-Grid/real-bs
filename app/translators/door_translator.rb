class DoorTranslator < DevTranslatorBase
  def self.to_flex(device)
    config = base_config_to_flex(device)
    cfg = device.dev_config || {}

    if cfg["defaultDoorMode"].is_a?(Hash)
      config[:defaultDoorMode] = cfg["defaultDoorMode"]
    end
    config[:activateStrikeOnRex] = cfg["activateStrikeOnRex"] unless cfg["activateStrikeOnRex"].nil?
    config[:strikeTime] = cfg["strikeTime"] unless cfg["strikeTime"].nil?
    config[:extendedStrikeTime] = cfg["extendedStrikeTime"] unless cfg["extendedStrikeTime"].nil?
    config[:heldTime] = cfg["heldTime"] unless cfg["heldTime"].nil?
    config[:extendedHeldTime] = cfg["extendedHeldTime"] unless cfg["extendedHeldTime"].nil?

    base_dev_fields(device).merge(
      doorConfig: config
    )
  end

  def self.from_flex(json)
    attrs = base_from_flex(json)
    config = base_config_from_flex(json, "doorConfig")

    cfg = json["doorConfig"]
    if cfg.is_a?(Hash)
      config["defaultDoorMode"] = cfg["defaultDoorMode"] if cfg.key?("defaultDoorMode") && cfg["defaultDoorMode"].is_a?(Hash)
      config["activateStrikeOnRex"] = cfg["activateStrikeOnRex"] if cfg.key?("activateStrikeOnRex")
      config["strikeTime"] = cfg["strikeTime"] if cfg.key?("strikeTime")
      config["extendedStrikeTime"] = cfg["extendedStrikeTime"] if cfg.key?("extendedStrikeTime")
      config["heldTime"] = cfg["heldTime"] if cfg.key?("heldTime")
      config["extendedHeldTime"] = cfg["extendedHeldTime"] if cfg.key?("extendedHeldTime")
    end

    attrs[:dev_config] = config if config.any?
    attrs
  end
end
