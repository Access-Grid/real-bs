require "test_helper"

class Api::HolTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @hc = HolidayCalendar.create!(name: "US Federal")
    @ht = HolidayType.create!(name: "Federal")
    @hol = Holiday.create!(
      name: "New Year",
      holiday_calendar: @hc,
      date: "2026-01-01",
      num_days: 1,
      repeat: true,
      num_years_repeat: 5,
      preserve_sched_day: false,
      all_hol_types: false
    )
    @hol.holiday_holiday_types.create!(holiday_type: @ht)
  end

  # -- Auth enforcement --

  test "GET /hol/list returns 401 without token" do
    get "/hol/list"
    assert_response :unauthorized
  end

  test "POST /hol/save returns 401 without token" do
    post "/hol/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /hol/list returns list response structure" do
    get "/hol/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /hol/list returns holidays with Flex fields" do
    get "/hol/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    hol = json["instanceList"].find { |h| h["unid"] == @hol.id }
    assert_not_nil hol
    assert_equal "New Year", hol["name"]
    assert_equal "2026-01-01", hol["date"]
    assert_equal 1, hol["numDays"]
    assert_equal true, hol["repeat"]
    assert_equal 5, hol["numYearsRepeat"]
    assert_not_nil hol["uuid"]

    assert_not_nil hol["holCal"]
    assert_equal @hc.id, hol["holCal"]["unid"]

    assert_equal 1, hol["holTypes"].length
    assert_equal @ht.id, hol["holTypes"][0]["unid"]
  end

  test "GET /hol/list supports pagination" do
    Holiday.create!(name: "Hol 2")
    Holiday.create!(name: "Hol 3")

    get "/hol/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /hol/save creates a holiday with holTypes" do
    assert_difference "Holiday.count", 1 do
      post "/hol/save",
        params: {
          name: "Independence Day",
          date: "2026-07-04",
          numDays: 1,
          repeat: true,
          numYearsRepeat: 10,
          preserveSchedDay: false,
          allHolTypes: false,
          holCal: { unid: @hc.id },
          holTypes: [{ unid: @ht.id }]
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Independence Day", json["instance"]["name"]
    assert_equal "2026-07-04", json["instance"]["date"]
    assert_not_nil json["instance"]["uuid"]
    assert_equal @hc.id, json["instance"]["holCal"]["unid"]
    assert_equal 1, json["instance"]["holTypes"].length
    assert_equal @ht.id, json["instance"]["holTypes"][0]["unid"]
  end

  test "POST /hol/save creates holiday without calendar" do
    post "/hol/save",
      params: { name: "Standalone Holiday" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_nil json["instance"]["holCal"]
  end

  test "POST /hol/save returns 422 without name" do
    post "/hol/save",
      params: { date: "2026-01-01" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /hol/update/{id} updates by unid" do
    post "/hol/update/#{@hol.id}",
      params: { name: "Updated Holiday", numDays: 2 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @hol.reload
    assert_equal "Updated Holiday", @hol.name
    assert_equal 2, @hol.num_days
  end

  test "POST /hol/update/{id} updates by uuid" do
    post "/hol/update/#{@hol.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @hol.reload.name
  end

  test "POST /hol/update/{id} updates holTypes" do
    ht2 = HolidayType.create!(name: "Company")
    post "/hol/update/#{@hol.id}",
      params: { holTypes: [{ unid: ht2.id }] },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["instance"]["holTypes"].length
    assert_equal ht2.id, json["instance"]["holTypes"][0]["unid"]
  end

  test "POST /hol/update/{id} without holTypes preserves existing" do
    post "/hol/update/#{@hol.id}",
      params: { name: "Renamed Only" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Renamed Only", json["instance"]["name"]
    assert_equal 1, json["instance"]["holTypes"].length
  end

  test "POST /hol/update/{id} returns 404 for unknown id" do
    post "/hol/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /hol/delete/{id} deletes by unid" do
    assert_difference "Holiday.count", -1 do
      post "/hol/delete/#{@hol.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /hol/delete/{id} deletes by uuid" do
    assert_difference "Holiday.count", -1 do
      post "/hol/delete/#{@hol.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /hol/delete/{id} cascades to holiday_holiday_types" do
    assert_difference "HolidayHolidayType.count", -1 do
      post "/hol/delete/#{@hol.id}",
        headers: { "sessionToken" => @token }
    end
  end

  test "POST /hol/delete/{id} returns 404 for unknown id" do
    post "/hol/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- show --

  test "GET /hol/show/{id} returns holiday by unid" do
    get "/hol/show/#{@hol.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @hol.id, json["instance"]["unid"]
    assert_equal @hol.name, json["instance"]["name"]
  end

  test "GET /hol/show/{id} returns 404 for unknown id" do
    get "/hol/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
