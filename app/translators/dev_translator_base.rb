class DevTranslatorBase
  def self.obj_ref(record)
    return nil unless record
    {
      unid: record.id,
      name: record.name,
      type: record.class.name
    }
  end

  def self.base_dev_fields(record, dev_type)
    {
      devType: dev_type,
      unid: record.id,
      uuid: record.uuid,
      name: record.name,
      enabled: true
    }
  end
end
