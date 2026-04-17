require "test_helper"
require_relative "../../lib/spcore_server"

class SpCoreServerTest < ActiveSupport::TestCase
  P = Z9::Spcore::Proto

  setup do
    @server = SpCoreServer.new(port: 0, auto_sync: false) # port 0 = OS picks free port
  end

  teardown do
    @server.stop
  end

  # -- Framing --

  test "HEADER_MAGIC is 0x3E4B" do
    assert_equal [0x3E, 0x4B], SpCoreServer::HEADER_MAGIC.bytes
  end

  # -- Start/stop lifecycle --

  test "starts and stops without error" do
    @server = SpCoreServer.new(port: find_free_port)
    @server.start
    assert_not_nil @server
    @server.stop
  end

  test "not connected initially" do
    assert_not @server.connected?
  end

  # -- TCP message framing round-trip --

  test "write and read message round trip" do
    port = find_free_port
    @server = SpCoreServer.new(port: port, auto_sync: false)
    @server.start

    # Connect as a fake Aporta client
    client = TCPSocket.new("127.0.0.1", port)

    # Read the identification message the server sends on connect
    id_msg = read_framed_message(client)
    assert_equal :IDENTIFICATION, id_msg.type
    assert_equal "real-bs-host", id_msg.identification.id

    # Send identification back (like Aporta would)
    write_framed_message(client, P::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: P::Identification.new(
        id: "test-aporta",
        protocolVersion: "1.0",
        softwareVersion: "0.0.1"
      )
    ))

    sleep 0.1 # let the server process

    assert @server.connected?
  ensure
    client&.close
  end

  test "PING echo" do
    port = find_free_port
    @server = SpCoreServer.new(port: port, auto_sync: false)
    @server.start

    client = TCPSocket.new("127.0.0.1", port)
    _id_msg = read_framed_message(client) # consume identification

    # Send PING
    write_framed_message(client, P::SpCoreMessage.new(type: :PING))

    # Should get PING back
    pong = read_framed_message(client)
    assert_equal :PING, pong.type
  ensure
    client&.close
  end

  test "send_db_change and receive DbChangeResp" do
    port = find_free_port
    @server = SpCoreServer.new(port: port, auto_sync: false)
    @server.start

    client = TCPSocket.new("127.0.0.1", port)
    _id_msg = read_framed_message(client)

    # Send identification from client
    write_framed_message(client, P::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: P::Identification.new(id: "test-aporta")
    ))
    sleep 0.1

    # Server sends DbChange
    db_change = P::DbChange.new(credDeleteAll: true)
    request_id = @server.send_db_change(db_change)
    assert request_id > 0

    # Client reads DbChange
    db_msg = read_framed_message(client)
    assert_equal :DB_CHANGE, db_msg.type
    assert_equal request_id, db_msg.dbChange.requestId
    assert db_msg.dbChange.credDeleteAll

    # Client sends DbChangeResp
    resp = P::DbChangeResp.new(requestId: request_id)
    write_framed_message(client, P::SpCoreMessage.new(
      type: :DB_CHANGE_RESP,
      dbChangeResp: resp
    ))

    # Server receives it
    received = @server.wait_for_db_change_resp(request_id, timeout: 2)
    assert_equal request_id, received.requestId
  ensure
    client&.close
  end

  test "send_dev_action" do
    port = find_free_port
    @server = SpCoreServer.new(port: port, auto_sync: false)
    @server.start

    client = TCPSocket.new("127.0.0.1", port)
    _id_msg = read_framed_message(client)
    write_framed_message(client, P::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: P::Identification.new(id: "test-aporta")
    ))
    sleep 0.1

    req = P::DevActionReq.new(
      devActionType: :DevActionType_DOOR_MOMENTARY_UNLOCK,
      devUnid: 42
    )
    request_id = @server.send_dev_action(req)

    msg = read_framed_message(client)
    assert_equal :DEV_ACTION_REQ, msg.type
    assert_equal request_id, msg.devActionReq.requestId
    assert_equal 42, msg.devActionReq.devUnid
  ensure
    client&.close
  end

  test "receives EVT messages" do
    port = find_free_port
    @server = SpCoreServer.new(port: port, auto_sync: false)
    @server.start

    client = TCPSocket.new("127.0.0.1", port)
    _id_msg = read_framed_message(client)
    write_framed_message(client, P::SpCoreMessage.new(
      type: :IDENTIFICATION,
      identification: P::Identification.new(id: "test-aporta")
    ))
    sleep 0.1

    # Client sends EVT
    evt = P::Evt.new(
      unid: 1,
      evtCode: :EvtCode_DOOR_ACCESS_GRANTED,
      evtDevRef: P::EvtDevRef.new(unid: 5)
    )
    write_framed_message(client, P::SpCoreMessage.new(
      type: :EVT,
      evt: [evt]
    ))

    received_evt = @server.wait_for_event(timeout: 2)
    assert_equal :EvtCode_DOOR_ACCESS_GRANTED, received_evt.evtCode
    assert_equal 5, received_evt.evtDevRef.unid
  ensure
    client&.close
  end

  private

  def find_free_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end

  def write_framed_message(socket, msg)
    body = P::SpCoreMessage.encode(msg)
    socket.write(SpCoreServer::HEADER_MAGIC)
    socket.write([body.bytesize].pack("N"))
    socket.write(body)
    socket.flush
  end

  def read_framed_message(socket)
    header = socket.read(2)
    raise "Bad header" unless header == SpCoreServer::HEADER_MAGIC
    length = socket.read(4).unpack1("N")
    body = socket.read(length)
    P::SpCoreMessage.decode(body)
  end
end
