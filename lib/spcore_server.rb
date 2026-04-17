require "socket"
require_relative "proto/SpCoreProto_pb"

# TCP server speaking the Z9 Open Community Protocol.
# Aporta connects as a client; this is the host side.
#
# Framing: 2-byte header (0x3E4B big-endian) + 4-byte body length (big-endian) + protobuf body
class SpCoreServer
  HEADER_MAGIC = [0x3E, 0x4B].pack("CC").freeze
  MAX_BODY_LENGTH = 0x0003FFFF

  attr_reader :port, :received_events, :received_db_change_resps, :connection

  def initialize(port: 9723)
    @port = port
    @received_events = []
    @received_db_change_resps = []
    @mutex = Mutex.new
    @connection = nil
    @request_id_counter = 0
    @running = false
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

  # Wait for Aporta to connect and complete identification
  def wait_for_connection(timeout: 30)
    deadline = Time.now + timeout
    until connected?
      raise "Timeout waiting for connection" if Time.now > deadline
      sleep 0.1
    end
  end

  # Send a DbChange message to Aporta and return the request_id
  def send_db_change(db_change)
    request_id = next_request_id
    db_change.requestId = request_id

    msg = Z9::Spcore::Proto::SpCoreMessage.new(
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

    msg = Z9::Spcore::Proto::SpCoreMessage.new(
      type: :DEV_ACTION_REQ,
      devActionReq: dev_action_req
    )
    write_message(msg)
    request_id
  end

  # Send EvtControl (e.g., start/stop event flow)
  def send_evt_control(evt_control)
    msg = Z9::Spcore::Proto::SpCoreMessage.new(
      type: :EVT_CONTROL,
      evtControl: evt_control
    )
    write_message(msg)
  end

  # Send TERMINATE to Aporta
  def send_terminate
    msg = Z9::Spcore::Proto::SpCoreMessage.new(type: :TERMINATE)
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
    msg = Z9::Spcore::Proto::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: Z9::Spcore::Proto::Identification.new(
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
      # Aporta identified itself -- nothing to do
    when :PING
      write_message(Z9::Spcore::Proto::SpCoreMessage.new(type: :PING), socket)
    when :DB_CHANGE_RESP
      @mutex.synchronize { @received_db_change_resps << msg.dbChangeResp }
    when :EVT
      @mutex.synchronize { @received_events.concat(msg.evt.to_a) }
    when :DEV_ACTION_RESP
      # Noted
    when :TERMINATE
      # Connection terminated
    end
  end

  def write_message(msg, socket = nil)
    socket ||= @connection
    body = Z9::Spcore::Proto::SpCoreMessage.encode(msg)
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

    Z9::Spcore::Proto::SpCoreMessage.decode(body)
  end

  def next_request_id
    @mutex.synchronize { @request_id_counter += 1 }
  end
end
