require "test_helper"
require_relative "../../lib/db_change_builder"

class DbChangeBuilderTest < ActiveSupport::TestCase
  P = Z9::Spcore::Proto

  # -- build_dev --

  test "build_dev maps IoController" do
    dev = IoController.create!(name: "Panel 1")
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal "Panel 1", proto.name
    assert_equal dev.id, proto.unid
    assert_equal true, proto.enabled
    assert_equal :DevType_IO_CONTROLLER, proto.devType
    assert_not_empty proto.uuid
  end

  test "build_dev maps Door" do
    dev = Door.create!(name: "Front Door")
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal :DevType_DOOR, proto.devType
  end

  test "build_dev maps CredReader" do
    dev = CredReader.create!(name: "Reader 1")
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal :DevType_CRED_READER, proto.devType
  end

  test "build_dev maps Sensor" do
    dev = Sensor.create!(name: "Contact 1")
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal :DevType_SENSOR, proto.devType
  end

  test "build_dev maps Actuator" do
    dev = Actuator.create!(name: "Strike 1")
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal :DevType_ACTUATOR, proto.devType
  end

  test "build_dev includes optional fields when present" do
    dev = IoController.create!(
      name: "Panel",
      external_id: "EXT-1",
      address: "192.168.1.1",
      logical_address: 3,
      mac_address: "AA:BB:CC:DD:EE:FF",
      port: 9723,
      speed: 9600,
      dev_sub_type: 1,
      dev_mod: 100,
      dev_platform: 42,
      dev_use: 2,
      time_zone: "America/New_York",
      ignore_daylight_savings: true
    )
    proto = DbChangeBuilder.build_dev(dev)

    assert_equal "EXT-1", proto.externalId
    assert_equal "192.168.1.1", proto.address
    assert_equal 3, proto.logicalAddress
    assert_equal "AA:BB:CC:DD:EE:FF", proto.macAddress
    assert_equal 9723, proto.port
    assert_equal 9600, proto.speed
    # devSubType, devMod, devPlatform, devUse are enum fields in proto;
    # verify they were set (non-zero)
    assert_not_equal 0, proto.devSubType
    assert_not_equal 0, proto.devMod
    assert_not_equal 0, proto.devPlatform
    assert_not_equal 0, proto.devUse
    assert_equal "America/New_York", proto.timeZone
    assert_equal true, proto.ignoreDaylightSavings
  end

  # -- build_dev with config extensions --

  test "build_dev for IoController includes extController with controllerConfig" do
    dev = IoController.create!(name: "Panel", dev_config: { "username" => "admin", "password" => "secret" })
    proto = DbChangeBuilder.build_dev(dev)

    assert_not_nil proto.extController
    assert_not_nil proto.extController.controllerConfig
    assert_equal "admin", proto.extController.controllerConfig.username
    assert_equal "secret", proto.extController.controllerConfig.password
  end

  test "build_dev for CredReader includes extCredReader with credReaderConfig" do
    dev = CredReader.create!(name: "Reader", dev_config: {
      "commType" => 6,
      "serialPortAddress" => "localhost:9843",
      "tamperType" => 2,
      "ledType" => 2
    })
    proto = DbChangeBuilder.build_dev(dev)

    assert_not_nil proto.extCredReader
    cfg = proto.extCredReader.credReaderConfig
    assert_not_nil cfg
    assert_equal :CredReaderCommType_OSDP_HALF_DUPLEX, cfg.commType
    assert_equal "localhost:9843", cfg.serialPortAddress
    assert_equal :CredReaderTamperType_OSDP, cfg.tamperType
    assert_equal :CredReaderLedType_OSDP, cfg.ledType
  end

  test "build_dev for Sensor includes extSensor with sensorConfig" do
    dev = Sensor.create!(name: "Contact", dev_config: { "invert" => true })
    proto = DbChangeBuilder.build_dev(dev)

    assert_not_nil proto.extSensor
    assert_not_nil proto.extSensor.sensorConfig
    assert_equal true, proto.extSensor.sensorConfig.invert
  end

  test "build_dev for Actuator includes extActuator with actuatorConfig" do
    dev = Actuator.create!(name: "Strike", dev_config: { "invert" => true })
    proto = DbChangeBuilder.build_dev(dev)

    assert_not_nil proto.extActuator
    assert_not_nil proto.extActuator.actuatorConfig
    assert_equal true, proto.extActuator.actuatorConfig.invert
  end

  test "build_dev for IoController without dev_config still includes extController" do
    dev = IoController.create!(name: "Panel")
    proto = DbChangeBuilder.build_dev(dev)

    assert_not_nil proto.extController
    assert_not_nil proto.extController.controllerConfig
  end

  test "build_dev maps parent hierarchy" do
    controller = IoController.create!(name: "Panel")
    door = Door.create!(name: "Door", logical_parent: controller)
    reader = CredReader.create!(name: "Reader", physical_parent: controller, logical_parent: door)

    proto = DbChangeBuilder.build_dev(reader)
    assert_equal controller.id, proto.physicalParentUnid
    assert_equal door.id, proto.logicalParentUnid
  end

  # -- build_cred --

  test "build_cred basic fields" do
    ct = CredentialType.create!(name: "26-bit Wiegand")
    cred = Credential.create!(name: "Badge 1", credential_type: ct, enabled: true)
    proto = DbChangeBuilder.build_cred(cred)

    assert_equal "Badge 1", proto.name
    assert_equal cred.id, proto.unid
    assert_equal true, proto.enabled
    assert_equal ct.id, proto.credTemplateUnid
    assert_not_empty proto.uuid
  end

  test "build_cred with card_pin JSON" do
    cred = Credential.create!(
      name: "Badge 2",
      card_pin: { "credNum" => 12345, "facilityCode" => 100, "pin" => "4567" }
    )
    proto = DbChangeBuilder.build_cred(cred)

    assert_not_nil proto.cardPin
    assert_not_nil proto.cardPin.credNum
    assert_equal 100, proto.cardPin.facilityCode
    assert_equal "4567", proto.cardPin.pin

    # Verify bigint encoding of credNum
    bytes = proto.cardPin.credNum.bytes
    assert_not_empty bytes
  end

  test "build_cred with door_access_modifiers" do
    cred = Credential.create!(
      name: "ADA Badge",
      door_access_modifiers: { "extDoorTime" => true }
    )
    proto = DbChangeBuilder.build_cred(cred)

    assert_not_nil proto.doorAccessModifiers
    assert_equal true, proto.doorAccessModifiers.extDoorTime
  end

  test "build_cred without door_access_modifiers" do
    cred = Credential.create!(name: "Badge No DAM")
    proto = DbChangeBuilder.build_cred(cred)
    assert_nil proto.doorAccessModifiers
  end

  test "build_cred without card_pin" do
    cred = Credential.create!(name: "Badge 3")
    proto = DbChangeBuilder.build_cred(cred)

    # cardPin should not be set (nil in proto3 optional)
    assert_nil proto.cardPin
  end

  test "build_cred includes privBindings" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "All Doors")
    sched = Schedule.create!(name: "Business Hours")
    door = Door.create!(name: "Front Door")

    # Binding with priv + schedRestriction
    cred.cred_priv_bindings.create!(
      access_rule_set: ars,
      schedule: sched,
      sched_restriction_invert: true
    )
    # Binding with devAsDoorAccessPriv
    cred.cred_priv_bindings.create!(
      dev_as_door_access_priv_unid: door.id
    )

    proto = DbChangeBuilder.build_cred(cred)

    assert_equal 2, proto.privBindings.size

    cpb1 = proto.privBindings[0]
    assert_equal ars.id, cpb1.privUnid
    assert_not_nil cpb1.schedRestriction
    assert_equal sched.id, cpb1.schedRestriction.schedUnid
    assert_equal true, cpb1.schedRestriction.invert

    cpb2 = proto.privBindings[1]
    assert_equal door.id, cpb2.devAsDoorAccessPrivUnid
    assert_equal 0, cpb2.privUnid # not set
  end

  test "build_cred without privBindings has empty proto list" do
    cred = Credential.create!(name: "Badge")
    proto = DbChangeBuilder.build_cred(cred)

    assert_equal 0, proto.privBindings.size
  end

  # -- build_cred_template --

  test "build_cred_template basic" do
    ct = CredentialType.create!(name: "26-bit", priority: 5)
    proto = DbChangeBuilder.build_cred_template(ct)

    assert_equal "26-bit", proto.name
    assert_equal ct.id, proto.unid
    assert_equal 5, proto.priority
  end

  test "build_cred_template with card_pin_template JSON" do
    dl = DataLayout.create!(name: "Standard")
    ct = CredentialType.create!(
      name: "26-bit",
      card_pin_template: {
        "credComponentPresence" => "REQUIRED",
        "credNumPresence" => "REQUIRED",
        "pinPresence" => "OPTIONAL",
        "dataLayout" => { "unid" => dl.id }
      }
    )
    proto = DbChangeBuilder.build_cred_template(ct)

    cpt = proto.cardPinTemplate
    assert_not_nil cpt
    assert_equal :CredComponentPresence_REQUIRED, cpt.credComponentPresence
    assert_equal :CredComponentPresence_REQUIRED, cpt.credNumPresence
    assert_equal :CredComponentPresence_OPTIONAL, cpt.pinPresence
    assert_equal dl.id, cpt.dataLayoutUnid
  end

  # -- build_data_format --

  test "build_data_format basic" do
    cf = CredentialFormat.create!(name: "26-bit Wiegand", min_bits: 26, max_bits: 26)
    proto = DbChangeBuilder.build_data_format(cf)

    assert_equal "26-bit Wiegand", proto.name
    assert_equal cf.id, proto.unid
    assert_equal :DataFormatType_BINARY, proto.dataFormatType
    assert_equal 26, proto.extBinaryFormat.minBits
    assert_equal 26, proto.extBinaryFormat.maxBits
  end

  test "build_data_format with elements JSON" do
    cf = CredentialFormat.create!(
      name: "26-bit Wiegand",
      min_bits: 26,
      max_bits: 26,
      elements: [
        { "num" => 0, "type" => "PARITY", "start" => 0, "len" => 1, "odd" => false, "srcStart" => 1, "srcLen" => 12 },
        { "num" => 1, "type" => "FIELD", "start" => 1, "len" => 8, "field" => "FACILITY_CODE" },
        { "num" => 2, "type" => "FIELD", "start" => 9, "len" => 16, "field" => "CRED_NUM" },
        { "num" => 3, "type" => "PARITY", "start" => 25, "len" => 1, "odd" => true, "srcStart" => 13, "srcLen" => 12 }
      ]
    )
    proto = DbChangeBuilder.build_data_format(cf)
    bf = proto.extBinaryFormat

    assert_equal 4, bf.elements.size

    # First element: even parity
    e0 = bf.elements[0]
    assert_equal :BinaryElementType_PARITY, e0.type
    assert_equal 0, e0.start
    assert_equal 1, e0.len
    assert_equal false, e0.extParityBinaryElement.odd
    assert_equal 1, e0.extParityBinaryElement.srcStart
    assert_equal 12, e0.extParityBinaryElement.srcLen

    # Second element: facility code field
    e1 = bf.elements[1]
    assert_equal :BinaryElementType_FIELD, e1.type
    assert_equal 1, e1.start
    assert_equal 8, e1.len
    assert_equal :DataFormatField_FACILITY_CODE, e1.extFieldBinaryElement.field

    # Third element: cred num field
    e2 = bf.elements[2]
    assert_equal :BinaryElementType_FIELD, e2.type
    assert_equal :DataFormatField_CRED_NUM, e2.extFieldBinaryElement.field

    # Fourth element: odd parity
    e3 = bf.elements[3]
    assert_equal :BinaryElementType_PARITY, e3.type
    assert_equal true, e3.extParityBinaryElement.odd
  end

  # -- build_data_layout --

  test "build_data_layout basic" do
    cf = CredentialFormat.create!(name: "26-bit")
    dl = DataLayout.create!(name: "Standard Layout", priority: 1, data_format: cf)
    proto = DbChangeBuilder.build_data_layout(dl)

    assert_equal "Standard Layout", proto.name
    assert_equal dl.id, proto.unid
    assert_equal :DataLayoutType_BASIC, proto.layoutType
    assert_equal 1, proto.priority
    assert_equal true, proto.enabled
    assert_equal cf.id, proto.extBasicDataLayout.dataFormatUnid
  end

  # -- build_priv --

  test "build_priv basic" do
    ars = AccessRuleSet.create!(name: "Main Doors")
    proto = DbChangeBuilder.build_priv(ars)

    assert_equal "Main Doors", proto.name
    assert_equal ars.id, proto.unid
    assert_equal :PrivType_DOOR, proto.privType
    assert_equal true, proto.enabled
  end

  test "build_priv with elements" do
    controller = IoController.create!(name: "Panel")
    door = Door.create!(name: "Front Door", physical_parent: controller)
    sched = Schedule.create!(name: "Business Hours")
    ars = AccessRuleSet.create!(name: "ARS")
    ars.door_access_priv_elements.create!(door: door, schedule: sched, sched_restriction_invert: false)

    proto = DbChangeBuilder.build_priv(ars)
    dap = proto.extDoorAccessPriv
    assert_equal 1, dap.elements.size

    el = dap.elements.first
    assert_equal door.id, el.doorUnid
    assert_equal sched.id, el.schedRestriction.schedUnid
    assert_equal false, el.schedRestriction.invert
  end

  # -- build_sched --

  test "build_sched basic" do
    s = Schedule.create!(name: "Business Hours")
    s.schedule_elements.create!(
      mon: true, tues: true, wed: true, thur: true, fri: true,
      sat: false, sun: false,
      start_time: "08:00", stop_time: "17:30",
      holidays: false, plus_days: 0
    )

    proto = DbChangeBuilder.build_sched(s)

    assert_equal "Business Hours", proto.name
    assert_equal s.id, proto.unid
    assert_equal 1, proto.elements.size

    se = proto.elements.first
    assert_includes se.schedDays, :SchedDay_MON
    assert_includes se.schedDays, :SchedDay_TUES
    assert_includes se.schedDays, :SchedDay_WED
    assert_includes se.schedDays, :SchedDay_THUR
    assert_includes se.schedDays, :SchedDay_FRI
    assert_not_includes se.schedDays, :SchedDay_SAT
    assert_not_includes se.schedDays, :SchedDay_SUN

    assert_equal 8, se.start.hour
    assert_equal 0, se.start.minute
    assert_equal 17, se.stop.hour
    assert_equal 30, se.stop.minute
    assert_equal false, se.holidays
    assert_equal 0, se.plusDays
  end

  # -- build_hol_type --

  test "build_hol_type" do
    ht = HolidayType.create!(name: "Federal Holiday")
    proto = DbChangeBuilder.build_hol_type(ht)

    assert_equal "Federal Holiday", proto.name
    assert_equal ht.id, proto.unid
    assert_not_empty proto.uuid
  end

  # -- build_hol_cal --

  test "build_hol_cal" do
    hc = HolidayCalendar.create!(name: "US 2026")
    proto = DbChangeBuilder.build_hol_cal(hc)

    assert_equal "US 2026", proto.name
    assert_equal hc.id, proto.unid
    assert_not_empty proto.uuid
  end

  # -- build_full_sync --

  test "build_full_sync includes all entity types" do
    # Create one of each entity
    IoController.create!(name: "Panel")
    Door.create!(name: "Door")
    CredentialType.create!(name: "26-bit")
    Credential.create!(name: "Badge 1")
    CredentialFormat.create!(name: "26-bit Wiegand")
    DataLayout.create!(name: "Standard")
    AccessRuleSet.create!(name: "All Doors")
    Schedule.create!(name: "24/7")
    HolidayType.create!(name: "Federal")
    HolidayCalendar.create!(name: "US")

    db_change = DbChangeBuilder.build_full_sync

    # Delete-all flags
    assert db_change.credDeleteAll
    assert db_change.credTemplateDeleteAll
    assert db_change.dataLayoutDeleteAll
    assert db_change.dataFormatDeleteAll
    assert db_change.devDeleteAll
    assert db_change.privDeleteAll
    assert db_change.holCalDeleteAll
    assert db_change.holTypeDeleteAll
    assert db_change.schedDeleteAll

    # Entity counts (at least 1 of each)
    assert db_change.dev.size >= 2, "Should have at least 2 devices"
    assert db_change.cred.size >= 1
    assert db_change.credTemplate.size >= 1
    assert db_change.dataFormat.size >= 1
    assert db_change.dataLayout.size >= 1
    assert db_change.priv.size >= 1
    assert db_change.sched.size >= 1
    assert db_change.holType.size >= 1
    assert db_change.holCal.size >= 1
  end

  test "build_full_sync encodes to valid protobuf" do
    IoController.create!(name: "Panel")
    db_change = DbChangeBuilder.build_full_sync

    msg = P::SpCoreMessage.new(type: :DB_CHANGE, dbChange: db_change)
    bytes = P::SpCoreMessage.encode(msg)
    assert bytes.bytesize > 0

    # Round-trip decode
    decoded = P::SpCoreMessage.decode(bytes)
    assert_equal :DB_CHANGE, decoded.type
    assert decoded.dbChange.devDeleteAll
  end

  # -- Helpers --

  test "bigint_to_bytes encodes correctly" do
    assert_equal [0x30, 0x39], DbChangeBuilder.bigint_to_bytes(12345).bytes
    assert_equal [0x01], DbChangeBuilder.bigint_to_bytes(1).bytes
    assert_equal [0x01, 0x00], DbChangeBuilder.bigint_to_bytes(256).bytes
    assert_equal [0x00], DbChangeBuilder.bigint_to_bytes(0).bytes
    assert_equal [0x00], DbChangeBuilder.bigint_to_bytes(nil).bytes
  end

  test "parse_hour and parse_minute" do
    assert_equal 8, DbChangeBuilder.parse_hour("08:30")
    assert_equal 30, DbChangeBuilder.parse_minute("08:30")
    assert_equal 17, DbChangeBuilder.parse_hour("17:00")
    assert_equal 0, DbChangeBuilder.parse_minute("17:00")
    assert_equal 0, DbChangeBuilder.parse_hour(nil)
    assert_equal 0, DbChangeBuilder.parse_minute(nil)
  end

  test "presence_enum maps strings and integers" do
    assert_equal :CredComponentPresence_REQUIRED, DbChangeBuilder.presence_enum("REQUIRED")
    assert_equal :CredComponentPresence_OPTIONAL, DbChangeBuilder.presence_enum("OPTIONAL")
    assert_equal :CredComponentPresence_ABSENT, DbChangeBuilder.presence_enum("ABSENT")
    assert_equal :CredComponentPresence_ABSENT, DbChangeBuilder.presence_enum(0)
    assert_equal :CredComponentPresence_REQUIRED, DbChangeBuilder.presence_enum(1)
    assert_equal :CredComponentPresence_OPTIONAL, DbChangeBuilder.presence_enum(2)
    assert_equal :CredComponentPresence_ABSENT, DbChangeBuilder.presence_enum(nil)
  end
end
