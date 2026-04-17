require_relative "proto/SpCoreProto_pb"
require_relative "proto/SpCoreProtoData_pb"
require_relative "proto/SpCoreProtoElements_pb"
require_relative "proto/SpCoreProtoEnums_pb"

# Builds a protobuf DbChange message from Rails models for download to Aporta.
class DbChangeBuilder
  P = Z9::Spcore::Proto

  # Build a full DbChange with all entities (full sync)
  def self.build_full_sync
    db_change = P::DbChange.new

    # Delete all first, then send current state
    db_change.credDeleteAll = true
    db_change.credTemplateDeleteAll = true
    db_change.dataLayoutDeleteAll = true
    db_change.dataFormatDeleteAll = true
    db_change.devDeleteAll = true
    db_change.privDeleteAll = true
    db_change.holCalDeleteAll = true
    db_change.holTypeDeleteAll = true
    db_change.schedDeleteAll = true

    # Devices
    Device.find_each { |dev| db_change.dev << build_dev(dev) }

    # Credentials
    Credential.find_each { |cred| db_change.cred << build_cred(cred) }

    # Credential templates
    CredentialType.find_each { |ct| db_change.credTemplate << build_cred_template(ct) }

    # Data formats
    CredentialFormat.find_each { |cf| db_change.dataFormat << build_data_format(cf) }

    # Data layouts
    DataLayout.find_each { |dl| db_change.dataLayout << build_data_layout(dl) }

    # Privileges (DoorAccessPriv)
    AccessRuleSet.find_each { |ars| db_change.priv << build_priv(ars) }

    # Schedules
    Schedule.includes(:schedule_elements).find_each { |s| db_change.sched << build_sched(s) }

    # Holiday types
    HolidayType.find_each { |ht| db_change.holType << build_hol_type(ht) }

    # Holiday calendars
    HolidayCalendar.find_each { |hc| db_change.holCal << build_hol_cal(hc) }

    db_change
  end

  # -- Device --
  def self.build_dev(dev)
    proto = P::Dev.new(
      name: dev.name,
      unid: dev.id,
      enabled: true,
      devType: dev_type_enum(dev)
    )
    proto.uuid = dev.uuid if dev.uuid.present?
    proto.externalId = dev.external_id if dev.external_id.present?
    proto.address = dev.address || ""
    proto.logicalAddress = dev.logical_address if dev.logical_address
    proto.macAddress = dev.mac_address if dev.mac_address.present?
    proto.port = dev.port if dev.port
    proto.speed = dev.speed if dev.speed
    proto.devSubType = dev.dev_sub_type if dev.dev_sub_type
    proto.devMod = dev.dev_mod if dev.dev_mod
    proto.devPlatform = dev.dev_platform if dev.dev_platform
    proto.devUse = dev.dev_use if dev.dev_use
    proto.timeZone = dev.time_zone if dev.time_zone.present?
    proto.ignoreDaylightSavings = dev.ignore_daylight_savings if dev.ignore_daylight_savings

    if dev.respond_to?(:physical_parent_id) && dev.physical_parent_id
      proto.physicalParentUnid = dev.physical_parent_id
    end
    if dev.respond_to?(:logical_parent_id) && dev.logical_parent_id
      proto.logicalParentUnid = dev.logical_parent_id
    end

    # Device-type-specific config extensions
    case dev.type
    when "IoController"
      proto.extController = P::Controller.new(controllerConfig: build_controller_config(dev))
    when "CredReader"
      proto.extCredReader = P::CredReader.new(credReaderConfig: build_cred_reader_config(dev))
    when "Sensor"
      proto.extSensor = P::Sensor.new(sensorConfig: build_sensor_config(dev))
    when "Actuator"
      proto.extActuator = P::Actuator.new(actuatorConfig: build_actuator_config(dev))
    end

    proto
  end

  # -- Credential --
  def self.build_cred(cred)
    proto = P::Cred.new(
      name: cred.name,
      unid: cred.id,
      enabled: cred.enabled.nil? ? true : cred.enabled
    )
    proto.uuid = cred.uuid if cred.uuid.present?

    if cred.credential_type_id
      proto.credTemplateUnid = cred.credential_type_id
    end

    # CardPin from JSON column
    cp = cred.card_pin
    if cp.is_a?(Hash) && cp.any?
      card_pin = P::CardPin.new
      if cp["credNum"]
        card_pin.credNum = P::BigIntegerData.new(
          bytes: bigint_to_bytes(cp["credNum"])
        )
      end
      card_pin.facilityCode = cp["facilityCode"].to_i if cp["facilityCode"]
      card_pin.pin = cp["pin"].to_s if cp["pin"]
      proto.cardPin = card_pin
    end

    # CredPrivBindings
    cred.cred_priv_bindings.each do |binding|
      cpb = P::CredPrivBinding.new
      cpb.unid = binding.id
      cpb.privUnid = binding.access_rule_set_id if binding.access_rule_set_id
      cpb.devAsDoorAccessPrivUnid = binding.dev_as_door_access_priv_unid if binding.dev_as_door_access_priv_unid
      if binding.schedule_id
        cpb.schedRestriction = P::SchedRestriction.new(
          schedUnid: binding.schedule_id,
          invert: binding.sched_restriction_invert || false
        )
      end
      proto.privBindings << cpb
    end

    proto
  end

  # -- CredTemplate --
  def self.build_cred_template(ct)
    proto = P::CredTemplate.new(
      name: ct.name,
      unid: ct.id,
      priority: ct.priority || 0
    )
    proto.uuid = ct.uuid if ct.uuid.present?

    # CardPinTemplate from JSON column
    cpt = ct.card_pin_template
    if cpt.is_a?(Hash) && cpt.any?
      card_pin_template = P::CardPinTemplate.new
      card_pin_template.credComponentPresence = presence_enum(cpt["credComponentPresence"])
      card_pin_template.credNumPresence = presence_enum(cpt["credNumPresence"])
      card_pin_template.pinPresence = presence_enum(cpt["pinPresence"])
      if cpt["dataLayout"].is_a?(Hash) && cpt["dataLayout"]["unid"]
        card_pin_template.dataLayoutUnid = cpt["dataLayout"]["unid"]
      end
      proto.cardPinTemplate = card_pin_template
    end

    proto
  end

  # -- DataFormat --
  def self.build_data_format(cf)
    proto = P::DataFormat.new(
      name: cf.name,
      unid: cf.id,
      dataFormatType: :DataFormatType_BINARY
    )
    proto.uuid = cf.uuid if cf.uuid.present?

    # BinaryFormat extension
    bf = P::BinaryFormat.new(
      minBits: cf.min_bits || 0,
      maxBits: cf.max_bits || 0,
      supportReverseRead: cf.support_reverse_read || false
    )

    # Binary elements from JSON column
    elems = cf.elements
    if elems.is_a?(Array)
      elems.each do |el|
        be = P::BinaryElement.new(
          num: el["num"] || 0,
          start: el["start"] || 0,
          len: el["len"] || 0
        )
        be.unid = el["unid"] if el["unid"]

        case el["type"]
        when "FIELD", 1
          be.type = :BinaryElementType_FIELD
          if el["field"]
            field_enum = case el["field"]
                         when "FACILITY_CODE" then :DataFormatField_FACILITY_CODE
                         else :DataFormatField_CRED_NUM
                         end
            be.extFieldBinaryElement = P::FieldBinaryElement.new(field: field_enum)
          end
        when "PARITY", 2
          be.type = :BinaryElementType_PARITY
          be.extParityBinaryElement = P::ParityBinaryElement.new(
            odd: el["odd"] || false,
            srcStart: el["srcStart"] || 0,
            srcLen: el["srcLen"] || 0
          )
        end

        bf.elements << be
      end
    end

    proto.extBinaryFormat = bf
    proto
  end

  # -- DataLayout --
  def self.build_data_layout(dl)
    proto = P::DataLayout.new(
      name: dl.name,
      unid: dl.id,
      layoutType: :DataLayoutType_BASIC,
      priority: dl.priority || 0,
      enabled: dl.enabled.nil? ? true : dl.enabled
    )
    proto.uuid = dl.uuid if dl.uuid.present?

    if dl.data_format_id
      proto.extBasicDataLayout = P::BasicDataLayout.new(
        dataFormatUnid: dl.data_format_id
      )
    end

    proto
  end

  # -- Priv (AccessRuleSet / DoorAccessPriv) --
  def self.build_priv(ars)
    proto = P::Priv.new(
      name: ars.name,
      unid: ars.id,
      enabled: true,
      privType: :PrivType_DOOR
    )
    proto.uuid = ars.uuid if ars.uuid.present?

    dap = P::DoorAccessPriv.new
    if ars.respond_to?(:door_access_priv_elements)
      ars.door_access_priv_elements.each do |el|
        dap_el = P::DoorAccessPrivElement.new
        dap_el.doorUnid = el.door_id if el.respond_to?(:door_id) && el.door_id
        if el.respond_to?(:schedule_id) && el.schedule_id
          dap_el.schedRestriction = P::SchedRestriction.new(
            schedUnid: el.schedule_id,
            invert: el.respond_to?(:sched_restriction_invert) ? (el.sched_restriction_invert || false) : false
          )
        end
        dap.elements << dap_el
      end
    end
    proto.extDoorAccessPriv = dap

    proto
  end

  # -- Schedule --
  def self.build_sched(sched)
    proto = P::Sched.new(
      name: sched.name,
      unid: sched.id
    )
    proto.uuid = sched.uuid if sched.uuid.present?
    proto.externalId = sched.external_id if sched.respond_to?(:external_id) && sched.external_id.present?

    sched.schedule_elements.each do |el|
      se = P::SchedElement.new(
        holidays: el.holidays || false,
        start: P::SqlTimeData.new(hour: parse_hour(el.start_time), minute: parse_minute(el.start_time), second: 0),
        stop: P::SqlTimeData.new(hour: parse_hour(el.stop_time), minute: parse_minute(el.stop_time), second: 0),
        plusDays: el.plus_days || 0
      )

      # Days of week
      se.schedDays << :SchedDay_MON if el.mon
      se.schedDays << :SchedDay_TUES if el.tues
      se.schedDays << :SchedDay_WED if el.wed
      se.schedDays << :SchedDay_THUR if el.thur
      se.schedDays << :SchedDay_FRI if el.fri
      se.schedDays << :SchedDay_SAT if el.sat
      se.schedDays << :SchedDay_SUN if el.sun

      # Holiday types
      if el.respond_to?(:holiday_types)
        el.holiday_types.each { |ht| se.holTypesUnid << ht.id }
      end

      proto.elements << se
    end

    proto
  end

  # -- HolType --
  def self.build_hol_type(ht)
    proto = P::HolType.new(name: ht.name, unid: ht.id)
    proto.uuid = ht.uuid if ht.uuid.present?
    proto.externalId = ht.external_id if ht.respond_to?(:external_id) && ht.external_id.present?
    proto
  end

  # -- HolCal --
  # Note: Individual Hol (holiday) entries are NOT part of the proto DbChange.
  # HolCal is just name/uuid/unid. Holidays reference their calendar via holCalUnid
  # but are not sent in the download protocol.
  def self.build_hol_cal(hc)
    proto = P::HolCal.new(name: hc.name, unid: hc.id)
    proto.uuid = hc.uuid if hc.uuid.present?
    proto
  end

  # -- DevConfig Proto Builders --

  def self.build_base_config(proto_config, dev)
    cfg = dev.dev_config || {}
    proto_config.username = cfg["username"] if cfg["username"].present?
    proto_config.password = cfg["password"] if cfg["password"].present?
    proto_config.devInitiatesConnection = cfg["devInitiatesConnection"] if cfg["devInitiatesConnection"]
    proto_config.disableEncryption = cfg["disableEncryption"] if cfg["disableEncryption"]

    if cfg["encryptionKeyRef"].is_a?(Hash) && cfg["encryptionKeyRef"]["unid"]
      proto_config.encryptionKeyRefUnid = cfg["encryptionKeyRef"]["unid"]
    end
    if cfg["encryptionKeyRefNext"].is_a?(Hash) && cfg["encryptionKeyRefNext"]["unid"]
      proto_config.encryptionKeyRefNextUnid = cfg["encryptionKeyRefNext"]["unid"]
    end

    proto_config
  end

  def self.build_controller_config(dev)
    build_base_config(P::ControllerConfig.new, dev)
  end

  def self.build_cred_reader_config(dev)
    config = build_base_config(P::CredReaderConfig.new, dev)
    cfg = dev.dev_config || {}

    if cfg["commType"]
      config.commType = CRED_READER_COMM_TYPE_MAP[cfg["commType"]] || cfg["commType"]
    end
    if cfg["tamperType"]
      config.tamperType = CRED_READER_TAMPER_TYPE_MAP[cfg["tamperType"]] || cfg["tamperType"]
    end
    if cfg["ledType"]
      config.ledType = CRED_READER_LED_TYPE_MAP[cfg["ledType"]] || cfg["ledType"]
    end
    config.serialPortAddress = cfg["serialPortAddress"] if cfg["serialPortAddress"].present?

    config
  end

  def self.build_sensor_config(dev)
    config = build_base_config(P::SensorConfig.new, dev)
    cfg = dev.dev_config || {}
    config.invert = cfg["invert"] if cfg["invert"]
    config
  end

  def self.build_actuator_config(dev)
    config = build_base_config(P::ActuatorConfig.new, dev)
    cfg = dev.dev_config || {}
    config.invert = cfg["invert"] if cfg["invert"]
    config
  end

  # CredReaderCommType integer -> proto enum symbol
  CRED_READER_COMM_TYPE_MAP = {
    1 => :CredReaderCommType_RESERVED1,
    2 => :CredReaderCommType_RESERVED2,
    3 => :CredReaderCommType_RESERVED3,
    4 => :CredReaderCommType_RESERVED4,
    5 => :CredReaderCommType_RESERVED5,
    6 => :CredReaderCommType_OSDP_HALF_DUPLEX,
    7 => :CredReaderCommType_RESERVED7,
    8 => :CredReaderCommType_RESERVED8,
    9 => :CredReaderCommType_RESERVED9,
    10 => :CredReaderCommType_RESERVED10
  }.freeze

  CRED_READER_TAMPER_TYPE_MAP = {
    1 => :CredReaderTamperType_RESERVED1,
    2 => :CredReaderTamperType_OSDP,
    3 => :CredReaderTamperType_RESERVED3
  }.freeze

  CRED_READER_LED_TYPE_MAP = {
    1 => :CredReaderLedType_RESERVED1,
    2 => :CredReaderLedType_OSDP,
    3 => :CredReaderLedType_RESERVED3
  }.freeze

  # -- Helpers --

  def self.dev_type_enum(dev)
    case dev.type
    when "IoController" then :DevType_IO_CONTROLLER
    when "Door" then :DevType_DOOR
    when "CredReader" then :DevType_CRED_READER
    when "Sensor" then :DevType_SENSOR
    when "Actuator" then :DevType_ACTUATOR
    else :DevType_IO_CONTROLLER
    end
  end

  def self.bigint_to_bytes(num)
    return "\x00".b if num.nil? || num == 0
    bytes = []
    n = num.to_i
    while n > 0
      bytes.unshift(n & 0xFF)
      n >>= 8
    end
    bytes.pack("C*")
  end

  def self.parse_hour(time_str)
    return 0 unless time_str
    time_str.split(":").first.to_i
  end

  def self.parse_minute(time_str)
    return 0 unless time_str
    parts = time_str.split(":")
    parts.length > 1 ? parts[1].to_i : 0
  end

  PRESENCE_MAP = {
    "ABSENT" => :CredComponentPresence_ABSENT,
    "REQUIRED" => :CredComponentPresence_REQUIRED,
    "OPTIONAL" => :CredComponentPresence_OPTIONAL,
    0 => :CredComponentPresence_ABSENT,
    1 => :CredComponentPresence_REQUIRED,
    2 => :CredComponentPresence_OPTIONAL
  }.freeze

  def self.presence_enum(val)
    PRESENCE_MAP[val] || :CredComponentPresence_ABSENT
  end
end
