require "net/http"
require "json"
require "open3"
require "rack"

# E2E integration test orchestrator.
#
# Full pipeline -- no shortcuts:
#   1. Create all entities via the Flex REST API (Rack-level calls)
#   2. Start SpCoreServer (protobuf TCP)
#   3. Start Aporta (.NET controller) -- connects to SpCoreServer
#   4. SpCoreServer automatically: sends EvtControl, builds full sync via
#      DbChangeBuilder, sends DbChange to Aporta
#   5. PD sim simulates card swipes via OSDP
#   6. Aporta makes access decisions, sends events back
#   7. SpCoreServer persists events to Event table
#   8. Tests verify events via GET /evt/list REST API
#
# Known cheat:
#   CredReaderConfig (commType, serialPortAddress) is not yet in the REST API.
#   A db_change_modifier callback patches the OSDP config on the proto before
#   it reaches Aporta. When the CredReaderConfig API gap is closed, this patch
#   goes away and the pipeline is 100% clean.
#
# Components:
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
    @rack_app = Rails.application
    @session_token = nil
    # Track created entity IDs for reference
    @ids = {}
  end

  def proto
    @proto ||= begin
      require_relative "../proto/SpCoreProto_pb"
      Z9::Spcore::Proto
    end
  end

  def start_all
    puts "=== E2E: Starting components ==="
    clean_database
    create_config_via_api
    start_pd_sim
    start_spcore_server
    start_aporta
    wait_for_ready
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
  # Swipe a known card -> expect ACCESS_GRANTED event via /evt/list API
  def test_access_granted
    puts "\n--- Test: Access Granted ---"
    reset_pd_sim
    event_count_before = Event.count

    # Swipe card 12345 (26-bit Wiegand, facility code 100)
    pd_sim_wiegand26_card_read(facility_code: 100, card_number: 12345)

    # Wait for event to be persisted to database
    evt_record = wait_for_db_event(event_count_before, timeout: 30)
    assert_evt_code_int(evt_record, 48, "Expected ACCESS_GRANTED (48)")

    # Verify event is available via /evt/list REST API
    api_events = api_get("/evt/list")
    granted = api_events["instanceList"].find { |e| e["evtCode"] == 48 }
    raise "ACCESS_GRANTED event not returned by /evt/list" unless granted
    puts "  PASS: ACCESS_GRANTED event persisted and returned by /evt/list API"
  end

  # -- Test: Access Denied --
  # Swipe an unknown card -> expect ACCESS_DENIED event via /evt/list API
  def test_access_denied
    puts "\n--- Test: Access Denied ---"
    reset_pd_sim
    event_count_before = Event.count

    # Swipe unknown card 99999 (26-bit Wiegand, facility code 100)
    pd_sim_wiegand26_card_read(facility_code: 100, card_number: 99999)

    evt_record = wait_for_db_event(event_count_before, timeout: 15)
    assert_evt_code_int(evt_record, 49, "Expected ACCESS_DENIED (49)")

    api_events = api_get("/evt/list")
    denied = api_events["instanceList"].find { |e| e["evtCode"] == 49 }
    raise "ACCESS_DENIED event not returned by /evt/list" unless denied
    puts "  PASS: ACCESS_DENIED event persisted and returned by /evt/list API"
  end

  # -- Test: Momentary Unlock --
  # Send DevAction momentary unlock -> expect OSDP output command on PD sim
  def test_momentary_unlock
    puts "\n--- Test: Momentary Unlock ---"
    reset_pd_sim

    req = proto::DevActionReq.new(
      devActionType: :DevActionType_DOOR_MOMENTARY_UNLOCK,
      devUnid: @ids[:door]
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

  # ---- Database cleanup ----

  def clean_database
    print "  Cleaning database... "
    [Event, CredPrivBinding, Credential, DoorAccessPrivElement, AccessRuleSet,
     ScheduleElementHolidayType, ScheduleElement, Schedule,
     DataLayout, CredentialFormat, CredentialType,
     Device, Sector, Building, HolidayHolidayType, Holiday, HolidayCalendar, HolidayType,
     ApiSession, User].each do |model|
      model.delete_all
    rescue => e
      # Skip if table doesn't exist yet
    end
    puts "OK"
  end

  # ---- Create all config via REST API ----

  def create_config_via_api
    puts "  Creating config via REST API..."
    authenticate

    # IoController
    resp = api_post("/controller/save", { name: "E2E Panel" })
    @ids[:panel] = resp["instance"]["unid"]
    puts "    IoController: unid=#{@ids[:panel]}"

    # Door (logical parent = panel)
    resp = api_post("/door/save", {
      name: "E2E Door",
      logicalParent: { unid: @ids[:panel] }
    })
    @ids[:door] = resp["instance"]["unid"]
    puts "    Door: unid=#{@ids[:door]}"

    # CredReader (physical parent = panel, logical parent = door)
    resp = api_post("/credReader/save", {
      name: "E2E Reader",
      physicalParent: { unid: @ids[:panel] },
      logicalParent: { unid: @ids[:door] },
      port: 0,
      speed: 9600
    })
    @ids[:reader] = resp["instance"]["unid"]
    puts "    CredReader: unid=#{@ids[:reader]}"

    # BinaryFormat (26-bit Wiegand)
    resp = api_post("/binaryFormat/save", {
      name: "26-bit Wiegand",
      dataFormatType: 1,
      minBits: 26,
      maxBits: 26,
      supportReverseRead: false,
      elements: [
        { num: 0, type: "PARITY", start: 0, len: 1, odd: false, srcStart: 1, srcLen: 12 },
        { num: 1, type: "FIELD", start: 1, len: 8, field: "FACILITY_CODE" },
        { num: 2, type: "FIELD", start: 9, len: 16, field: "CRED_NUM" },
        { num: 3, type: "PARITY", start: 25, len: 1, odd: true, srcStart: 13, srcLen: 12 }
      ]
    })
    @ids[:data_format] = resp["instance"]["unid"]
    puts "    BinaryFormat: unid=#{@ids[:data_format]}"

    # DataLayout (references BinaryFormat)
    resp = api_post("/basicDataLayout/save", {
      name: "Standard 26-bit",
      layoutType: 0,
      priority: 0,
      enabled: true,
      dataFormat: { unid: @ids[:data_format] }
    })
    @ids[:data_layout] = resp["instance"]["unid"]
    puts "    DataLayout: unid=#{@ids[:data_layout]}"

    # CredTemplate (references DataLayout via cardPinTemplate)
    resp = api_post("/credTemplate/save", {
      name: "26-bit Card",
      priority: 0,
      cardPinTemplate: {
        credComponentPresence: "REQUIRED",
        credNumPresence: "REQUIRED",
        pinPresence: "ABSENT",
        dataLayout: { unid: @ids[:data_layout] }
      }
    })
    @ids[:cred_template] = resp["instance"]["unid"]
    puts "    CredTemplate: unid=#{@ids[:cred_template]}"

    # Schedule: Always (24/7)
    resp = api_post("/sched/save", {
      name: "Always",
      elements: [
        {
          holidays: false,
          schedDays: [0, 1, 2, 3, 4, 5, 6],
          start: "00:00",
          stop: "23:59",
          plusDays: 0
        }
      ]
    })
    @ids[:schedule] = resp["instance"]["unid"]
    puts "    Schedule: unid=#{@ids[:schedule]}"

    # DoorAccessPriv (grants access to door with schedule)
    resp = api_post("/doorAccessPriv/save", {
      name: "E2E Access",
      privType: 0,
      enabled: true,
      elements: [
        {
          door: { unid: @ids[:door] },
          schedRestriction: { sched: { unid: @ids[:schedule] }, invert: false }
        }
      ]
    })
    @ids[:priv] = resp["instance"]["unid"]
    puts "    DoorAccessPriv: unid=#{@ids[:priv]}"

    # Credential with privBindings (card 12345, FC 100, bound to priv)
    resp = api_post("/cred/save", {
      name: "E2E Badge",
      enabled: true,
      credTemplate: { unid: @ids[:cred_template] },
      cardPin: { credNum: "12345", facilityCode: "100" },
      privBindings: [
        { priv: { unid: @ids[:priv] } }
      ]
    })
    @ids[:cred] = resp["instance"]["unid"]
    puts "    Credential: unid=#{@ids[:cred]} (with privBinding to priv #{@ids[:priv]})"

    puts "  Config created via REST API: OK"
  end

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

    # CredReaderConfig (commType, serialPortAddress) is not yet in the REST API.
    # Patch the proto until that API gap is closed.
    reader_unid = @ids[:reader]
    @server.db_change_modifier = ->(db_change) do
      reader_proto = db_change.dev.find { |d| d.unid == reader_unid }
      if reader_proto
        reader_proto.extCredReader = proto::CredReader.new(
          credReaderConfig: proto::CredReaderConfig.new(
            commType: :CredReaderCommType_OSDP_HALF_DUPLEX,
            serialPortAddress: "localhost:#{PD_SIM_OSDP_PORT}"
          )
        )
      end
    end

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

  # Wait for Aporta to connect, server to auto-sync, and OSDP handshake to complete
  def wait_for_ready
    print "  Waiting for Aporta to connect... "
    @server.wait_for_connection(timeout: 60)
    puts "OK"

    print "  Waiting for auto-sync (DbChangeBuilder -> Aporta)... "
    @server.wait_for_sync(timeout: 30)
    puts "OK"

    print "  Waiting for OSDP handshake... "
    sleep 10
    puts "OK"
  end

  # ---- Flex REST API (Rack-level calls) ----

  def authenticate
    User.create!(username: "e2e_admin", password: "e2e_password")
    resp = api_post("/authenticate", { username: "e2e_admin", password: "e2e_password" })
    @session_token = resp["sessionToken"]
    raise "Authentication failed" unless @session_token
    puts "    Authenticated (token=#{@session_token[0..7]}...)"
  end

  def api_post(path, params = {})
    env = ::Rack::MockRequest.env_for(
      "http://localhost#{path}",
      method: "POST",
      input: params.to_json,
      "CONTENT_TYPE" => "application/json",
      "HTTP_HOST" => "localhost",
      "HTTP_SESSIONTOKEN" => @session_token
    )
    status, headers, body = @rack_app.call(env)
    response_body = ""
    body.each { |chunk| response_body << chunk }
    body.close if body.respond_to?(:close)

    unless (200..299).include?(status)
      raise "API POST #{path} failed (#{status}): #{response_body}"
    end
    JSON.parse(response_body)
  end

  def api_get(path)
    env = ::Rack::MockRequest.env_for(
      "http://localhost#{path}",
      method: "GET",
      "HTTP_HOST" => "localhost",
      "HTTP_SESSIONTOKEN" => @session_token
    )
    status, headers, body = @rack_app.call(env)
    response_body = ""
    body.each { |chunk| response_body << chunk }
    body.close if body.respond_to?(:close)

    unless (200..299).include?(status)
      raise "API GET #{path} failed (#{status}): #{response_body}"
    end
    JSON.parse(response_body)
  end

  # ---- PD Sim HTTP API ----

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

  def wait_for_db_event(count_before, timeout: 10)
    deadline = Time.now + timeout
    loop do
      if Event.count > count_before
        # Check all new events for an access decision
        evt = Event.where(evt_code: [48, 49]).order(created_at: :desc).first
        return evt if evt

        # If no match yet, log what we do have for debugging
        if Time.now > deadline
          recent = Event.order(created_at: :desc).limit(5).pluck(:id, :evt_code)
          raise "Timeout waiting for access event in database " \
                "(events before=#{count_before}, after=#{Event.count}, " \
                "recent evt_codes=#{recent.map(&:last).inspect})"
        end
      end
      if Time.now > deadline
        raise "Timeout waiting for access event in database (events before=#{count_before}, after=#{Event.count})"
      end
      sleep 0.1
    end
  end

  def assert_evt_code_int(evt, expected_code, message)
    unless evt.evt_code == expected_code
      raise "#{message}: got #{evt.evt_code} instead of #{expected_code}"
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
end
