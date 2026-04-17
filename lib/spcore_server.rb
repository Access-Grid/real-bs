require "socket"
require_relative "proto/SpCoreProto_pb"

# TCP server speaking the Z9 Open Community Protocol.
# Aporta connects as a client; this is the host side.
#
# Lifecycle:
#   1. Host listens on TCP port
#   2. Aporta connects; host sends IDENTIFICATION
#   3. Aporta sends IDENTIFICATION back
#   4. Host sends EvtControl (START_CONTINUOUS) to begin event flow
#   5. Host builds full sync from database via DbChangeBuilder and sends DbChange
#   6. Aporta applies config, sends DbChangeResp
#   7. Aporta sends events as they occur; host persists to Event table
#
# Framing: 2-byte header (0x3E4B big-endian) + 4-byte body length (big-endian) + protobuf body
class SpCoreServer
  HEADER_MAGIC = [0x3E, 0x4B].pack("CC").freeze
  MAX_BODY_LENGTH = 0x0003FFFF

  P = Z9::Spcore::Proto

  attr_reader :port, :received_events, :received_db_change_resps, :connection

  # auto_sync: when true (default), automatically builds full sync from database
  # and sends to Aporta when it connects. Set to false for unit tests that test
  # protocol mechanics without the full sync lifecycle.
  def initialize(port: 9723, auto_sync: true)
    @port = port
    @auto_sync = auto_sync
    @received_events = []
    @received_db_change_resps = []
    @mutex = Mutex.new
    @connection = nil
    @request_id_counter = 0
    @running = false
    @synced = false
    @sync_error = nil
  end

  def start
    @running = true
    @server = TCPServer.new("0.0.0.0", @port)
    @accept_thread = Thread.new { accept_loop }
  end

  def stop
    @running = false
    @connection&.close rescue nil
    @server&.close rescue nil
    @accept_thread&.join(2)
  end

  def connected?
    @connection && !@connection.closed?
  end

  # Wait for Aporta to connect
  def wait_for_connection(timeout: 30)
    deadline = Time.now + timeout
    until connected?
      raise "Timeout waiting for connection" if Time.now > deadline
      sleep 0.1
    end
  end

  # Wait for automatic full sync to complete after Aporta connects
  def wait_for_sync(timeout: 30)
    deadline = Time.now + timeout
    loop do
      @mutex.synchronize do
        raise @sync_error if @sync_error
        return true if @synced
      end
      raise "Timeout waiting for sync to complete" if Time.now > deadline
      sleep 0.1
    end
  end

  # Send a DbChange message to Aporta and return the request_id
  def send_db_change(db_change)
    request_id = next_request_id
    db_change.requestId = request_id

    msg = P::SpCoreMessage.new(
      type: :DB_CHANGE,
      dbChange: db_change
    )
    write_message(msg)
    request_id
  end

  # Send a DevActionReq to Aporta
  def send_dev_action(dev_action_req)
    request_id = next_request_id
    dev_action_req.requestId = request_id

    msg = P::SpCoreMessage.new(
      type: :DEV_ACTION_REQ,
      devActionReq: dev_action_req
    )
    write_message(msg)
    request_id
  end

  # Send EvtControl (e.g., start/stop event flow)
  def send_evt_control(evt_control)
    msg = P::SpCoreMessage.new(
      type: :EVT_CONTROL,
      evtControl: evt_control
    )
    write_message(msg)
  end

  # Send TERMINATE to Aporta
  def send_terminate
    msg = P::SpCoreMessage.new(type: :TERMINATE)
    write_message(msg)
  end

  # Wait for a DbChangeResp with the given request_id
  def wait_for_db_change_resp(request_id, timeout: 10)
    deadline = Time.now + timeout
    loop do
      @mutex.synchronize do
        resp = @received_db_change_resps.find { |r| r.requestId == request_id }
        return resp if resp
      end
      raise "Timeout waiting for DbChangeResp" if Time.now > deadline
      sleep 0.05
    end
  end

  # Wait for events matching a condition
  def wait_for_event(timeout: 10)
    deadline = Time.now + timeout
    initial_count = @mutex.synchronize { @received_events.size }
    loop do
      @mutex.synchronize do
        return @received_events.last if @received_events.size > initial_count
      end
      raise "Timeout waiting for event" if Time.now > deadline
      sleep 0.05
    end
  end

  private

  def accept_loop
    while @running
      begin
        socket = @server.accept
        @connection = socket
        @read_thread = Thread.new { read_loop(socket) }

        # Host sends identification first
        send_identification(socket)
      rescue IOError, Errno::EBADF
        break unless @running
      end
    end
  end

  def send_identification(socket = nil)
    socket ||= @connection
    msg = P::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: P::Identification.new(
        id: "real-bs-host",
        protocolVersion: "1.0",
        softwareVersion: "0.1.0",
        maxBodyLength: MAX_BODY_LENGTH
      )
    )
    write_message(msg, socket)
  end

  def read_loop(socket)
    while @running && !socket.closed?
      begin
        msg = read_message(socket)
        next unless msg
        handle_message(msg, socket)
      rescue EOFError, IOError, Errno::ECONNRESET
        break
      end
    end
  end

  def handle_message(msg, socket)
    case msg.type
    when :IDENTIFICATION
      # Aporta identified itself -- start event flow and send full sync
      Thread.new { perform_full_sync } if @auto_sync
    when :PING
      write_message(P::SpCoreMessage.new(type: :PING), socket)
    when :DB_CHANGE_RESP
      @mutex.synchronize { @received_db_change_resps << msg.dbChangeResp }
    when :EVT
      events = msg.evt.to_a
      @mutex.synchronize { @received_events.concat(events) }
      persist_events(events)
    when :DEV_ACTION_RESP
      # Noted
    when :TERMINATE
      # Connection terminated
    end
  end

  # Automatic full sync: called when Aporta connects and identifies.
  # Builds current database state as protobuf and sends to controller.
  def perform_full_sync
    # Start continuous event flow
    send_evt_control(P::EvtControl.new(
      evtFlowControl: :EvtFlowControl_START_CONTINUOUS
    ))
    sleep 0.5

    # Build proto from database
    require_relative "db_change_builder"
    db_change = DbChangeBuilder.build_full_sync

    # Send to Aporta and wait for acknowledgment
    request_id = send_db_change(db_change)
    resp = wait_for_db_change_resp(request_id, timeout: 15)

    if resp.exception && !resp.exception.empty?
      raise "DbChange rejected by controller: #{resp.exception}"
    end

    @mutex.synchronize { @synced = true }
  rescue => e
    @mutex.synchronize { @sync_error = e }
  end

  # Persist proto events to the Event table
  def persist_events(proto_events)
    proto_events.each do |evt|
      attrs = {
        evt_code: resolve_enum(evt.evtCode),
        hw_time: millis_to_time(evt.hwTime),
        db_time: Time.current,
        hw_time_zone: evt.hwTimeZone.presence,
        evt_sub_code: resolve_enum(evt.evtSubCode),
        external_evt_code_text: evt.externalEvtCodeText.presence,
        external_evt_code_id: evt.externalEvtCodeId.presence,
        external_sub_code_text: evt.externalSubCodeText.presence,
        external_sub_code_id: evt.externalSubCodeId.presence,
        priority: evt.priority,
        data: evt.data.presence,
        consumed: evt.consumed
      }
      attrs[:evt_dev_ref] = evt_ref_to_hash(evt.evtDevRef) if evt.evtDevRef
      attrs[:evt_cred_ref] = evt_cred_ref_to_hash(evt.evtCredRef) if evt.evtCredRef
      Event.create!(attrs)
    rescue => e
      # Log but don't crash the read loop
      puts "  WARN: Failed to persist event: #{e.message}"
    end
  end

  def millis_to_time(dt)
    return nil unless dt && dt.millis > 0
    Time.at(dt.millis / 1000.0).utc
  end

  def resolve_enum(val)
    return nil if val.nil?
    if val.is_a?(Symbol)
      # Enum symbols follow the pattern EnumName_VALUE_NAME (e.g., EvtCode_DOOR_ACCESS_GRANTED).
      # The enum class name is the part before the first underscore.
      enum_name = val.to_s.split("_", 2).first
      begin
        P.const_get(enum_name).resolve(val)
      rescue
        nil
      end
    else
      val
    end
  end

  def evt_ref_to_hash(ref)
    return nil unless ref
    h = { "unid" => ref.unid, "name" => ref.name.presence }
    h["uuid"] = ref.uuid if ref.respond_to?(:uuid) && ref.uuid.present?
    h.compact
  end

  def evt_cred_ref_to_hash(ref)
    return nil unless ref
    h = { "unid" => ref.unid, "name" => ref.name.presence }
    h["facilityCode"] = ref.facilityCode if ref.facilityCode > 0
    h["uuid"] = ref.uuid if ref.respond_to?(:uuid) && ref.uuid.present?
    h.compact
  end

  def write_message(msg, socket = nil)
    socket ||= @connection
    body = P::SpCoreMessage.encode(msg)
    header = HEADER_MAGIC + [body.bytesize].pack("N")
    socket.write(header)
    socket.write(body)
    socket.flush
  end

  def read_message(socket)
    header = socket.read(2)
    raise EOFError unless header && header.bytesize == 2
    raise "Bad header: #{header.unpack1("H*")}" unless header == HEADER_MAGIC

    length_bytes = socket.read(4)
    raise EOFError unless length_bytes && length_bytes.bytesize == 4
    length = length_bytes.unpack1("N")
    raise "Body too large: #{length}" if length > MAX_BODY_LENGTH

    body = socket.read(length)
    raise EOFError unless body && body.bytesize == length

    P::SpCoreMessage.decode(body)
  end

  def next_request_id
    @mutex.synchronize { @request_id_counter += 1 }
  end
end
