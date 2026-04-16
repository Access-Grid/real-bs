require "test_helper"

class Api::EvtTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @evt1 = Event.create!(
      hw_time: "2026-04-16T08:00:00Z",
      db_time: "2026-04-16T08:00:01Z",
      hw_time_zone: "America/New_York",
      evt_code: 48,
      evt_sub_code: 0,
      priority: 0,
      consumed: false,
      evt_dev_ref: { "unid" => 1, "name" => "Front Door", "devType" => 5 },
      evt_controller_ref: { "unid" => 2, "name" => "Main Controller", "devType" => 1 },
      evt_cred_ref: { "unid" => 10, "name" => "Badge 001", "credNum" => "12345" },
      evt_modifiers: { "usedCard" => true, "usedPin" => false }
    )

    @evt2 = Event.create!(
      hw_time: "2026-04-16T09:00:00Z",
      db_time: "2026-04-16T09:00:01Z",
      evt_code: 49,
      evt_sub_code: 14,
      priority: 0,
      consumed: false
    )

    @evt3 = Event.create!(
      hw_time: "2026-04-16T10:00:00Z",
      db_time: "2026-04-16T10:00:01Z",
      evt_code: 48,
      priority: 0,
      consumed: false
    )
  end

  # -- Auth enforcement --

  test "GET /evt/list returns 401 without token" do
    get "/evt/list"
    assert_response :unauthorized
  end

  test "GET /evt/show/{id} returns 401 without token" do
    get "/evt/show/#{@evt1.id}"
    assert_response :unauthorized
  end

  # -- List --

  test "GET /evt/list returns list response structure" do
    get "/evt/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /evt/list returns events with Flex fields" do
    get "/evt/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 3
    evt = json["instanceList"].find { |e| e["unid"] == @evt1.id }
    assert_not_nil evt
    assert_equal 48, evt["evtCode"]
    assert_equal 0, evt["evtSubCode"]
    assert_equal 0, evt["priority"]
    assert_equal false, evt["consumed"]
    assert_not_nil evt["uuid"]
    assert_not_nil evt["hwTime"]
    assert_not_nil evt["dbTime"]
    assert_equal "America/New_York", evt["hwTimeZone"]

    assert_not_nil evt["evtDevRef"]
    assert_equal 1, evt["evtDevRef"]["unid"]
    assert_equal "Front Door", evt["evtDevRef"]["name"]

    assert_not_nil evt["evtControllerRef"]
    assert_equal 2, evt["evtControllerRef"]["unid"]

    assert_not_nil evt["evtCredRef"]
    assert_equal "Badge 001", evt["evtCredRef"]["name"]

    assert_not_nil evt["evtModifiers"]
    assert_equal true, evt["evtModifiers"]["usedCard"]
  end

  test "GET /evt/list defaults to descending order" do
    get "/evt/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    events = json["instanceList"]
    # Most recent first
    hw_times = events.map { |e| e["hwTime"] }.compact
    assert_equal hw_times, hw_times.sort.reverse
  end

  test "GET /evt/list order=asc returns ascending" do
    get "/evt/list", params: { order: "asc" }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    events = json["instanceList"]
    hw_times = events.map { |e| e["hwTime"] }.compact
    assert_equal hw_times, hw_times.sort
  end

  test "GET /evt/list order=desc returns descending" do
    get "/evt/list", params: { order: "desc" }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    events = json["instanceList"]
    hw_times = events.map { |e| e["hwTime"] }.compact
    assert_equal hw_times, hw_times.sort.reverse
  end

  # -- Pagination --

  test "GET /evt/list supports pagination" do
    get "/evt/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Show --

  test "GET /evt/show/{id} returns event by unid" do
    get "/evt/show/#{@evt1.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["instance"]
    assert_equal @evt1.id, json["instance"]["unid"]
    assert_equal 48, json["instance"]["evtCode"]
    assert_equal "Front Door", json["instance"]["evtDevRef"]["name"]
  end

  test "GET /evt/show/{id} returns event by uuid" do
    get "/evt/show/#{@evt1.uuid}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @evt1.id, json["instance"]["unid"]
  end

  test "GET /evt/show/{id} returns 404 for unknown id" do
    get "/evt/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  test "GET /evt/show/{id} returns 404 for unknown uuid" do
    get "/evt/show/nonexistent-uuid", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
