class SensorTranslator < DevTranslatorBase
  def self.to_flex(device)
    base_dev_fields(device).merge(
      sensorConfig: {}
    )
  end

  def self.from_flex(json)
    base_from_flex(json)
  end
end
