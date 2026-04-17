class EvtTranslator
  def self.to_flex(evt)
    {
      unid: evt.id,
      uuid: evt.uuid,
      version: evt.version_counter || 0,
      tag: evt.tag,
      hwTime: evt.hw_time&.iso8601,
      dbTime: evt.db_time&.iso8601,
      hwTimeZone: evt.hw_time_zone,
      evtCode: evt.evt_code,
      externalEvtCodeText: evt.external_evt_code_text,
      externalEvtCodeId: evt.external_evt_code_id,
      evtSubCode: evt.evt_sub_code,
      externalSubCodeText: evt.external_sub_code_text,
      externalSubCodeId: evt.external_sub_code_id,
      evtModifiers: evt.evt_modifiers,
      priority: evt.priority,
      data: evt.data,
      evtDevRef: evt.evt_dev_ref,
      evtControllerRef: evt.evt_controller_ref,
      evtCredRef: evt.evt_cred_ref,
      evtSchedRef: evt.evt_sched_ref,
      consumed: evt.consumed || false
    }
  end

  def self.from_flex(json)
    attrs = {}
    attrs[:version_counter] = json["version"] if json.key?("version")
    attrs[:tag] = json["tag"] if json.key?("tag")
    attrs[:hw_time] = json["hwTime"] if json.key?("hwTime")
    attrs[:db_time] = json["dbTime"] if json.key?("dbTime")
    attrs[:hw_time_zone] = json["hwTimeZone"] if json.key?("hwTimeZone")
    attrs[:evt_code] = json["evtCode"] if json.key?("evtCode")
    attrs[:external_evt_code_text] = json["externalEvtCodeText"] if json.key?("externalEvtCodeText")
    attrs[:external_evt_code_id] = json["externalEvtCodeId"] if json.key?("externalEvtCodeId")
    attrs[:evt_sub_code] = json["evtSubCode"] if json.key?("evtSubCode")
    attrs[:external_sub_code_text] = json["externalSubCodeText"] if json.key?("externalSubCodeText")
    attrs[:external_sub_code_id] = json["externalSubCodeId"] if json.key?("externalSubCodeId")
    attrs[:evt_modifiers] = json["evtModifiers"] if json.key?("evtModifiers")
    attrs[:priority] = json["priority"] if json.key?("priority")
    attrs[:data] = json["data"] if json.key?("data")
    attrs[:evt_dev_ref] = json["evtDevRef"] if json.key?("evtDevRef")
    attrs[:evt_controller_ref] = json["evtControllerRef"] if json.key?("evtControllerRef")
    attrs[:evt_cred_ref] = json["evtCredRef"] if json.key?("evtCredRef")
    attrs[:evt_sched_ref] = json["evtSchedRef"] if json.key?("evtSchedRef")
    attrs[:consumed] = json["consumed"] if json.key?("consumed")
    attrs
  end
end
