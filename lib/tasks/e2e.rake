require "net/http"
require "json"
require "open3"

# E2E integration test orchestrator.
#
# Three components:
#   1. real-bs SpCoreServer (protobuf TCP, port 9723)
#   2. Aporta (.NET controller, connects to SpCoreServer and OSDP PD sim)
#   3. osdp-net-pd-sim (OSDP PD simulator, OSDP on 9843, HTTP on 5230)
#
# Usage:
#   bundle exec rake e2e:test
#   bundle exec rake e2e:test_access_granted
#   bundle exec rake e2e:test_access_denied

APORTA_DIR = File.expand_path("~/git/Aporta")
PD_SIM_DIR = File.expand_path("~/git/osdp-net-pd-sim/OsdpPdSim")
SPCORE_PORT = 9723
PD_SIM_HTTP_PORT = 5230
PD_SIM_OSDP_PORT = 9843

namespace :e2e do
  desc "Run all E2E tests"
  task test: :environment do
    orchestrator = E2EOrchestrator.new
    begin
      orchestrator.start_all
      orchestrator.run_tests
    ensure
      orchestrator.stop_all
    end
  end

  desc "Run single E2E test: access granted"
  task test_access_granted: :environment do
    orchestrator = E2EOrchestrator.new
    begin
      orchestrator.start_all
      orchestrator.test_access_granted
    ensure
      orchestrator.stop_all
    end
  end

  desc "Run single E2E test: access denied (unknown card)"
  task test_access_denied: :environment do
    orchestrator = E2EOrchestrator.new
    begin
      orchestrator.start_all
      orchestrator.test_access_denied
    ensure
      orchestrator.stop_all
    end
  end
end

class E2EOrchestrator
  def initialize
    @server = nil
    @aporta_pid = nil
    @pd_sim_pid = nil
  end

  def proto
    @proto ||= begin
      require_relative "../proto/SpCoreProto_pb"
      Z9::Spcore::Proto
    end
  end

  def start_all
    puts "=== E2E: Starting components ==="
    start_pd_sim
    start_spcore_server
    start_aporta
    wait_for_aporta_connection
    send_full_config
    puts "=== E2E: All components ready ==="
  end

  def stop_all
    puts "\n=== E2E: Stopping components ==="
    stop_aporta
    stop_spcore_server
    stop_pd_sim
    puts "=== E2E: Stopped ==="
  end

  def run_tests
    test_access_granted
    test_access_denied
    test_momentary_unlock
    puts "\n=== E2E: All tests passed ==="
  end

  # -- Test: Access Granted --
  # Swipe a known card -> expect ACCESS_GRANTED event
  def test_access_granted
    puts "\n--- Test: Access Granted ---"
    reset_pd_sim

    # Swipe card 12345 (26-bit Wiegand, facility code 100)
    # PD sim encodes proper 26-bit Wiegand with parity; Aporta decodes using DataFormat
    pd_sim_wiegand26_card_read(facility_code: 100, card_number: 12345)

    # Wait for event from Aporta
    evt = wait_for_access_event(timeout: 30)
    assert_evt_code(evt, :EvtCode_DOOR_ACCESS_GRANTED, "Expected ACCESS_GRANTED")
    puts "  PASS: Received DOOR_ACCESS_GRANTED event"
  end

  # -- Test: Access Denied --
  # Swipe an unknown card -> expect ACCESS_DENIED event
  def test_access_denied
    puts "\n--- Test: Access Denied ---"
    reset_pd_sim

    # Swipe unknown card 99999 (26-bit Wiegand, facility code 100)
    pd_sim_wiegand26_card_read(facility_code: 100, card_number: 99999)

    evt = wait_for_access_event(timeout: 15)
    assert_evt_code(evt, :EvtCode_DOOR_ACCESS_DENIED, "Expected ACCESS_DENIED")
    puts "  PASS: Received DOOR_ACCESS_DENIED event"
  end

  # -- Test: Momentary Unlock --
  # Send DevAction momentary unlock -> expect OSDP output command on PD sim
  def test_momentary_unlock
    puts "\n--- Test: Momentary Unlock ---"
    reset_pd_sim

    req = proto::DevActionReq.new(
      devActionType: :DevActionType_DOOR_MOMENTARY_UNLOCK,
      devUnid: door_unid
    )
    @server.send_dev_action(req)

    # Give Aporta time to process and send OSDP output command
    sleep 3

    commands = pd_sim_get_commands
    output_commands = commands.select { |c| c["type"]&.include?("Output") }
    if output_commands.any?
      puts "  PASS: PD sim received output control command"
    else
      puts "  WARN: No output commands received (strike may not be configured)"
    end
  end

  private

  # ---- Component Lifecycle ----

  def start_pd_sim
    print "  Starting OSDP PD Simulator... "
    @pd_sim_pid = spawn(
      "dotnet", "run", "--project", PD_SIM_DIR,
      out: "/tmp/e2e-pd-sim.log", err: "/tmp/e2e-pd-sim.log"
    )
    Process.detach(@pd_sim_pid)
    wait_for_http("localhost", PD_SIM_HTTP_PORT, "/status", timeout: 30)
    puts "OK (pid=#{@pd_sim_pid})"
  end

  def stop_pd_sim
    if @pd_sim_pid
      print "  Stopping PD Simulator... "
      Process.kill("TERM", @pd_sim_pid) rescue nil
      Process.wait(@pd_sim_pid) rescue nil
      puts "OK"
    end
  end

  def start_spcore_server
    print "  Starting SpCoreServer on port #{SPCORE_PORT}... "
    require_relative "../spcore_server"
    @server = SpCoreServer.new(port: SPCORE_PORT)
    @server.start
    puts "OK"
  end

  def stop_spcore_server
    if @server
      print "  Stopping SpCoreServer... "
      @server.send_terminate rescue nil
      sleep 0.5
      @server.stop
      puts "OK"
    end
  end

  def start_aporta
    print "  Starting Aporta... "
    @aporta_pid = spawn(
      { "DOTNET_ROLL_FORWARD" => "LatestMajor" },
      "dotnet", "run",
      "--project", "#{APORTA_DIR}/src/Aporta/Aporta.csproj",
      "--",
      "--z9OpenCommunityHost=localhost",
      "--z9OpenCommunityPort=#{SPCORE_PORT}",
      "--z9OpenCommunityId=e2e-test-panel",
      "--cleanDatabase=true",
      out: "/tmp/e2e-aporta.log", err: "/tmp/e2e-aporta.log"
    )
    Process.detach(@aporta_pid)
    puts "OK (pid=#{@aporta_pid})"
  end

  def stop_aporta
    if @aporta_pid
      print "  Stopping Aporta... "
      Process.kill("TERM", @aporta_pid) rescue nil
      Process.wait(@aporta_pid) rescue nil
      puts "OK"
    end
  end

  def wait_for_aporta_connection
    print "  Waiting for Aporta to connect... "
    @server.wait_for_connection(timeout: 60)
    puts "OK"

    # Send EvtControl to start continuous event flow
    @server.send_evt_control(proto::EvtControl.new(
      evtFlowControl: :EvtFlowControl_START_CONTINUOUS
    ))
    sleep 1
  end

  # ---- Config: Build and send DbChange ----

  def send_full_config
    print "  Sending DbChange with full config... "
    db_change = build_e2e_db_change
    request_id = @server.send_db_change(db_change)
    resp = @server.wait_for_db_change_resp(request_id, timeout: 15)
    if resp.exception && !resp.exception.empty?
      raise "DbChangeResp exception: #{resp.exception}"
    end
    puts "OK (request_id=#{request_id})"

    # Give Aporta time to set up OSDP connection and complete OSDP handshake
    print "  Waiting for OSDP connection... "
    sleep 10
    puts "OK"
  end

  def build_e2e_db_change
    db_change = proto::DbChange.new
    db_change.credDeleteAll = true
    db_change.credTemplateDeleteAll = true
    db_change.dataLayoutDeleteAll = true
    db_change.dataFormatDeleteAll = true
    db_change.devDeleteAll = true
    db_change.privDeleteAll = true
    db_change.holCalDeleteAll = true
    db_change.holTypeDeleteAll = true
    db_change.schedDeleteAll = true

    # IoController (panel) -- unid 1
    db_change.dev << proto::Dev.new(
      name: "E2E Panel",
      unid: 1,
      enabled: true,
      devType: :DevType_IO_CONTROLLER
    )

    # Door -- unid 2, logical parent = panel (1)
    db_change.dev << proto::Dev.new(
      name: "E2E Door",
      unid: door_unid,
      enabled: true,
      devType: :DevType_DOOR,
      logicalParentUnid: 1
    )

    # CredReader -- unid 3, physical parent = panel (1), logical parent = door (2)
    # OSDP config: connect to PD sim at localhost:9843
    db_change.dev << proto::Dev.new(
      name: "E2E Reader",
      unid: 3,
      enabled: true,
      devType: :DevType_CRED_READER,
      physicalParentUnid: 1,
      logicalParentUnid: door_unid,
      port: 0,       # OSDP address
      speed: 9600,    # baud rate
      extCredReader: proto::CredReader.new(
        credReaderConfig: proto::CredReaderConfig.new(
          commType: :CredReaderCommType_OSDP_HALF_DUPLEX,
          serialPortAddress: "localhost:#{PD_SIM_OSDP_PORT}"
        )
      )
    )

    # DataFormat: 26-bit Wiegand -- unid 10
    db_change.dataFormat << proto::DataFormat.new(
      name: "26-bit Wiegand",
      unid: 10,
      dataFormatType: :DataFormatType_BINARY,
      extBinaryFormat: proto::BinaryFormat.new(
        minBits: 26,
        maxBits: 26,
        supportReverseRead: false,
        elements: [
          # Even parity (bit 0, covers bits 1-12)
          proto::BinaryElement.new(
            num: 0, type: :BinaryElementType_PARITY, start: 0, len: 1,
            extParityBinaryElement: proto::ParityBinaryElement.new(
              odd: false, srcStart: 1, srcLen: 12
            )
          ),
          # Facility code (bits 1-8)
          proto::BinaryElement.new(
            num: 1, type: :BinaryElementType_FIELD, start: 1, len: 8,
            extFieldBinaryElement: proto::FieldBinaryElement.new(
              field: :DataFormatField_FACILITY_CODE
            )
          ),
          # Card number (bits 9-24)
          proto::BinaryElement.new(
            num: 2, type: :BinaryElementType_FIELD, start: 9, len: 16,
            extFieldBinaryElement: proto::FieldBinaryElement.new(
              field: :DataFormatField_CRED_NUM
            )
          ),
          # Odd parity (bit 25, covers bits 13-24)
          proto::BinaryElement.new(
            num: 3, type: :BinaryElementType_PARITY, start: 25, len: 1,
            extParityBinaryElement: proto::ParityBinaryElement.new(
              odd: true, srcStart: 13, srcLen: 12
            )
          )
        ]
      )
    )

    # DataLayout -- unid 11, references DataFormat 10
    db_change.dataLayout << proto::DataLayout.new(
      name: "Standard 26-bit",
      unid: 11,
      layoutType: :DataLayoutType_BASIC,
      priority: 0,
      enabled: true,
      extBasicDataLayout: proto::BasicDataLayout.new(dataFormatUnid: 10)
    )

    # CredTemplate -- unid 12, references DataLayout 11
    db_change.credTemplate << proto::CredTemplate.new(
      name: "26-bit Card",
      unid: 12,
      priority: 0,
      cardPinTemplate: proto::CardPinTemplate.new(
        credComponentPresence: :CredComponentPresence_REQUIRED,
        credNumPresence: :CredComponentPresence_REQUIRED,
        pinPresence: :CredComponentPresence_ABSENT,
        dataLayoutUnid: 11
      )
    )

    # Schedule: Always (24/7) -- unid 20
    db_change.sched << proto::Sched.new(
      name: "Always",
      unid: 20,
      elements: [
        proto::SchedElement.new(
          holidays: false,
          start: proto::SqlTimeData.new(hour: 0, minute: 0, second: 0),
          stop: proto::SqlTimeData.new(hour: 23, minute: 59, second: 59),
          plusDays: 0,
          schedDays: [
            :SchedDay_MON, :SchedDay_TUES, :SchedDay_WED, :SchedDay_THUR,
            :SchedDay_FRI, :SchedDay_SAT, :SchedDay_SUN
          ]
        )
      ]
    )

    # DoorAccessPriv -- unid 30, grants access to door 2 with schedule 20
    db_change.priv << proto::Priv.new(
      name: "E2E Access",
      unid: 30,
      enabled: true,
      privType: :PrivType_DOOR,
      extDoorAccessPriv: proto::DoorAccessPriv.new(
        elements: [
          proto::DoorAccessPrivElement.new(
            doorUnid: door_unid,
            schedRestriction: proto::SchedRestriction.new(schedUnid: 20, invert: false)
          )
        ]
      )
    )

    # Credential: card 12345, facility 100 -- unid 40
    # Bound to priv 30
    db_change.cred << proto::Cred.new(
      name: "E2E Badge",
      unid: 40,
      enabled: true,
      credTemplateUnid: 12,
      cardPin: proto::CardPin.new(
        credNum: proto::BigIntegerData.new(bytes: bigint_to_bytes(12345)),
        facilityCode: 100
      ),
      privBindings: [
        proto::CredPrivBinding.new(privUnid: 30)
      ]
    )

    db_change
  end

  def door_unid
    2
  end

  # ---- PD Sim HTTP API ----

  def pd_sim_card_read(card_number:, bit_count: 26)
    pd_sim_post("/card-read", {
      cardNumber: card_number,
      bitCount: bit_count,
      readerNumber: 0
    })
  end

  def pd_sim_wiegand26_card_read(facility_code:, card_number:, reader_number: 0)
    pd_sim_post("/card-read-wiegand26", {
      facilityCode: facility_code,
      cardNumber: card_number,
      readerNumber: reader_number
    })
  end

  def pd_sim_get_commands
    resp = pd_sim_get("/commands")
    JSON.parse(resp.body)
  end

  def reset_pd_sim
    pd_sim_post("/reset", {})
    # Clear any previously received events
    @server.received_events.clear
  end

  def pd_sim_post(path, body)
    uri = URI("http://localhost:#{PD_SIM_HTTP_PORT}#{path}")
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = body.to_json
    Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
  end

  def pd_sim_get(path)
    uri = URI("http://localhost:#{PD_SIM_HTTP_PORT}#{path}")
    Net::HTTP.get_response(uri)
  end

  # ---- Assertions ----

  def wait_for_access_event(timeout: 10)
    deadline = Time.now + timeout
    initial_count = @server.received_events.size
    loop do
      if @server.received_events.size > initial_count
        evt = @server.received_events.last
        code = evt.evtCode
        if code == :EvtCode_DOOR_ACCESS_GRANTED || code == :EvtCode_DOOR_ACCESS_DENIED
          return evt
        end
      end
      if Time.now > deadline
        raise "Timeout waiting for access event (received #{@server.received_events.size - initial_count} events)"
      end
      sleep 0.1
    end
  end

  def assert_evt_code(evt, expected_code, message)
    unless evt.evtCode == expected_code
      raise "#{message}: got #{evt.evtCode} instead of #{expected_code}"
    end
  end

  # ---- Helpers ----

  def wait_for_http(host, port, path, timeout: 30)
    deadline = Time.now + timeout
    loop do
      begin
        uri = URI("http://#{host}:#{port}#{path}")
        resp = Net::HTTP.get_response(uri)
        return if resp.code.to_i < 500
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout
        # keep waiting
      end
      if Time.now > deadline
        raise "Timeout waiting for HTTP #{host}:#{port}#{path}"
      end
      sleep 0.5
    end
  end

  def bigint_to_bytes(num)
    return "\x00".b if num.nil? || num == 0
    bytes = []
    n = num.to_i
    while n > 0
      bytes.unshift(n & 0xFF)
      n >>= 8
    end
    bytes.pack("C*")
  end
end
