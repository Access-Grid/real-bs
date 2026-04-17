require "test_helper"

class Api::SchedTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ht = HolidayType.create!(name: "Federal")
    @schedule = Schedule.create!(name: "Business Hours", external_id: "EXT-1")
    el = @schedule.schedule_elements.create!(
      mon: true, tues: true, wed: true, thur: true, fri: true,
      start_time: "09:00", stop_time: "17:00"
    )
    el.schedule_element_holiday_types.create!(holiday_type: @ht)
  end

  # -- Auth enforcement --

  test "GET /sched/list returns 401 without token" do
    get "/sched/list"
    assert_response :unauthorized
  end

  test "POST /sched/save returns 401 without token" do
    post "/sched/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /sched/list returns list response structure" do
    get "/sched/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /sched/list returns schedules with Flex fields" do
    get "/sched/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    sched = json["instanceList"].find { |s| s["unid"] == @schedule.id }
    assert_not_nil sched
    assert_equal "Business Hours", sched["name"]
    assert_equal "EXT-1", sched["externalId"]
    assert_not_nil sched["uuid"]
    assert_equal 1, sched["elements"].length

    elem = sched["elements"][0]
    assert_equal [0, 1, 2, 3, 4], elem["schedDays"]
    assert_equal "09:00", elem["start"]
    assert_equal "17:00", elem["stop"]
    assert_equal 0, elem["plusDays"]
    assert_equal 1, elem["holTypes"].length
    assert_equal @ht.id, elem["holTypes"][0]["unid"]
  end

  test "GET /sched/list supports pagination" do
    Schedule.create!(name: "Sched 2")
    Schedule.create!(name: "Sched 3")

    get "/sched/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /sched/save creates a schedule with elements" do
    assert_difference "Schedule.count", 1 do
      post "/sched/save",
        params: {
          name: "Night Shift",
          externalId: "NS-1",
          elements: [
            {
              schedDays: [0, 1, 2, 3, 4],
              start: "22:00",
              stop: "06:00",
              plusDays: 1,
              holidays: false
            }
          ]
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Night Shift", json["instance"]["name"]
    assert_equal "NS-1", json["instance"]["externalId"]
    assert_not_nil json["instance"]["uuid"]
    assert_equal 1, json["instance"]["elements"].length

    elem = json["instance"]["elements"][0]
    assert_equal [0, 1, 2, 3, 4], elem["schedDays"]
    assert_equal "22:00", elem["start"]
    assert_equal "06:00", elem["stop"]
    assert_equal 1, elem["plusDays"]
  end

  test "POST /sched/save creates elements with holTypes" do
    post "/sched/save",
      params: {
        name: "Holiday Sched",
        elements: [
          {
            schedDays: [],
            holidays: true,
            holTypes: [{ unid: @ht.id }]
          }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    elem = json["instance"]["elements"][0]
    assert_equal true, elem["holidays"]
    assert_equal 1, elem["holTypes"].length
    assert_equal @ht.id, elem["holTypes"][0]["unid"]
  end

  test "POST /sched/save returns 422 without name" do
    post "/sched/save",
      params: { externalId: "X" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /sched/update/{id} updates by unid" do
    post "/sched/update/#{@schedule.id}",
      params: { name: "Updated Hours" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Hours", @schedule.reload.name
  end

  test "POST /sched/update/{id} updates by uuid" do
    post "/sched/update/#{@schedule.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @schedule.reload.name
  end

  test "POST /sched/update/{id} replaces elements" do
    post "/sched/update/#{@schedule.id}",
      params: {
        elements: [
          { schedDays: [5, 6], start: "10:00", stop: "14:00" }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["instance"]["elements"].length
    assert_equal [5, 6], json["instance"]["elements"][0]["schedDays"]
  end

  test "POST /sched/update/{id} without elements preserves existing" do
    post "/sched/update/#{@schedule.id}",
      params: { name: "Renamed Only" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Renamed Only", json["instance"]["name"]
    assert_equal 1, json["instance"]["elements"].length
  end

  test "POST /sched/update/{id} returns 404 for unknown id" do
    post "/sched/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /sched/delete/{id} deletes by unid" do
    assert_difference "Schedule.count", -1 do
      post "/sched/delete/#{@schedule.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /sched/delete/{id} deletes by uuid" do
    assert_difference "Schedule.count", -1 do
      post "/sched/delete/#{@schedule.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /sched/delete/{id} cascades to elements" do
    assert_difference "ScheduleElement.count", -1 do
      post "/sched/delete/#{@schedule.id}",
        headers: { "sessionToken" => @token }
    end
  end

  test "POST /sched/delete/{id} returns 404 for unknown id" do
    post "/sched/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- show --

  test "GET /sched/show/{id} returns schedule by unid" do
    get "/sched/show/#{@schedule.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @schedule.id, json["instance"]["unid"]
    assert_equal @schedule.name, json["instance"]["name"]
  end

  test "GET /sched/show/{id} returns 404 for unknown id" do
    get "/sched/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
