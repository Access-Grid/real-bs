require "test_helper"

class Api::HolCalTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @hc = HolidayCalendar.create!(name: "US Federal")
  end

  # -- Auth enforcement --

  test "GET /holCal/list returns 401 without token" do
    get "/holCal/list"
    assert_response :unauthorized
  end

  test "POST /holCal/save returns 401 without token" do
    post "/holCal/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /holCal/list returns list response structure" do
    get "/holCal/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /holCal/list returns calendars with Flex fields" do
    get "/holCal/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    cal = json["instanceList"].find { |c| c["unid"] == @hc.id }
    assert_not_nil cal
    assert_equal "US Federal", cal["name"]
    assert_not_nil cal["uuid"]
  end

  test "GET /holCal/list supports pagination" do
    HolidayCalendar.create!(name: "Cal 2")
    HolidayCalendar.create!(name: "Cal 3")

    get "/holCal/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /holCal/save creates a holiday calendar" do
    assert_difference "HolidayCalendar.count", 1 do
      post "/holCal/save",
        params: { name: "Company Calendar" },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Company Calendar", json["instance"]["name"]
    assert_not_nil json["instance"]["uuid"]
  end

  test "POST /holCal/save returns 422 without name" do
    post "/holCal/save",
      params: {},
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /holCal/update/{id} updates by unid" do
    post "/holCal/update/#{@hc.id}",
      params: { name: "Updated Calendar" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Calendar", @hc.reload.name
  end

  test "POST /holCal/update/{id} updates by uuid" do
    post "/holCal/update/#{@hc.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @hc.reload.name
  end

  test "POST /holCal/update/{id} returns 404 for unknown id" do
    post "/holCal/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /holCal/delete/{id} deletes by unid" do
    assert_difference "HolidayCalendar.count", -1 do
      post "/holCal/delete/#{@hc.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /holCal/delete/{id} deletes by uuid" do
    assert_difference "HolidayCalendar.count", -1 do
      post "/holCal/delete/#{@hc.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /holCal/delete/{id} cascades to holidays" do
    Holiday.create!(name: "New Year", holiday_calendar: @hc)
    assert_difference "Holiday.count", -1 do
      post "/holCal/delete/#{@hc.id}",
        headers: { "sessionToken" => @token }
    end
  end

  test "POST /holCal/delete/{id} returns 404 for unknown id" do
    post "/holCal/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
