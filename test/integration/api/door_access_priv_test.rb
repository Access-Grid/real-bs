require "test_helper"

class Api::DoorAccessPrivTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @controller_dev = IoController.create!(name: "Main Controller")
    @door = Door.create!(name: "Front Door", physical_parent: @controller_dev)
    @door2 = Door.create!(name: "Back Door", physical_parent: @controller_dev)

    @ars = AccessRuleSet.create!(name: "Building Access", priv_type: 0, enabled: true)
    @ars.door_access_priv_elements.create!(door: @door, sched_restriction_invert: false)
  end

  # -- Auth enforcement --

  test "GET /doorAccessPriv/list returns 401 without token" do
    get "/doorAccessPriv/list"
    assert_response :unauthorized
  end

  test "POST /doorAccessPriv/save returns 401 without token" do
    post "/doorAccessPriv/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /doorAccessPriv/list returns list response structure" do
    get "/doorAccessPriv/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /doorAccessPriv/list returns privs with Flex fields" do
    get "/doorAccessPriv/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    priv = json["instanceList"].find { |p| p["unid"] == @ars.id }
    assert_not_nil priv
    assert_equal "Building Access", priv["name"]
    assert_equal 0, priv["privType"]
    assert_equal true, priv["enabled"]
    assert_not_nil priv["uuid"]
    assert_equal 1, priv["elements"].length

    elem = priv["elements"][0]
    assert_not_nil elem["door"]
    assert_equal @door.id, elem["door"]["unid"]
    assert_equal "Front Door", elem["door"]["name"]
  end

  # -- Pagination --

  test "GET /doorAccessPriv/list supports pagination" do
    AccessRuleSet.create!(name: "Priv 2")
    AccessRuleSet.create!(name: "Priv 3")

    get "/doorAccessPriv/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /doorAccessPriv/save creates a door access priv" do
    assert_difference "AccessRuleSet.count", 1 do
      post "/doorAccessPriv/save",
        params: {
          name: "New Priv",
          privType: 0,
          enabled: true,
          elements: [
            { door: { unid: @door.id }, schedRestriction: { invert: false } }
          ]
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "New Priv", json["instance"]["name"]
    assert_equal 0, json["instance"]["privType"]
    assert_not_nil json["instance"]["uuid"]
    assert_equal 1, json["instance"]["elements"].length
    assert_equal @door.id, json["instance"]["elements"][0]["door"]["unid"]
  end

  test "POST /doorAccessPriv/save with multiple elements" do
    post "/doorAccessPriv/save",
      params: {
        name: "Multi Door Priv",
        elements: [
          { door: { unid: @door.id } },
          { door: { unid: @door2.id }, schedRestriction: { invert: true } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["instance"]["elements"].length
  end

  test "POST /doorAccessPriv/save resolves door by uuid" do
    post "/doorAccessPriv/save",
      params: {
        name: "UUID Door Priv",
        elements: [
          { door: { uuid: @door.uuid } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @door.id, json["instance"]["elements"][0]["door"]["unid"]
  end

  test "POST /doorAccessPriv/save returns 422 without name" do
    post "/doorAccessPriv/save",
      params: { privType: 0 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /doorAccessPriv/update/{id} updates by unid" do
    post "/doorAccessPriv/update/#{@ars.id}",
      params: { name: "Updated Priv", enabled: false },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @ars.reload
    assert_equal "Updated Priv", @ars.name
    assert_equal false, @ars.enabled
  end

  test "POST /doorAccessPriv/update/{id} updates by uuid" do
    post "/doorAccessPriv/update/#{@ars.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @ars.reload.name
  end

  test "POST /doorAccessPriv/update/{id} updates elements" do
    post "/doorAccessPriv/update/#{@ars.id}",
      params: {
        elements: [
          { door: { unid: @door.id } },
          { door: { unid: @door2.id } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["instance"]["elements"].length
  end

  test "POST /doorAccessPriv/update/{id} without elements preserves existing" do
    post "/doorAccessPriv/update/#{@ars.id}",
      params: { name: "Renamed Only" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Renamed Only", json["instance"]["name"]
    assert_equal 1, json["instance"]["elements"].length
  end

  test "POST /doorAccessPriv/update/{id} returns 404 for unknown id" do
    post "/doorAccessPriv/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /doorAccessPriv/delete/{id} deletes by unid" do
    assert_difference "AccessRuleSet.count", -1 do
      post "/doorAccessPriv/delete/#{@ars.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /doorAccessPriv/delete/{id} deletes by uuid" do
    assert_difference "AccessRuleSet.count", -1 do
      post "/doorAccessPriv/delete/#{@ars.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /doorAccessPriv/delete/{id} cascades to elements" do
    assert_difference "DoorAccessPrivElement.count", -1 do
      post "/doorAccessPriv/delete/#{@ars.id}",
        headers: { "sessionToken" => @token }
    end
  end

  test "POST /doorAccessPriv/delete/{id} returns 404 for unknown id" do
    post "/doorAccessPriv/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- Schedule in elements --

  test "POST /doorAccessPriv/save creates element with schedule ObjRef" do
    sched = Schedule.create!(name: "Business Hours")
    post "/doorAccessPriv/save",
      params: {
        name: "Sched Priv",
        elements: [
          { door: { unid: @door.id }, schedRestriction: { sched: { unid: sched.id }, invert: false } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    elem = json["instance"]["elements"][0]
    assert_not_nil elem["schedRestriction"]["sched"]
    assert_equal sched.id, elem["schedRestriction"]["sched"]["unid"]
    assert_equal "Business Hours", elem["schedRestriction"]["sched"]["name"]
  end

  test "POST /doorAccessPriv/update/{id} updates element schedule" do
    sched = Schedule.create!(name: "Night Shift")
    post "/doorAccessPriv/update/#{@ars.id}",
      params: {
        elements: [
          { door: { unid: @door.id }, schedRestriction: { sched: { unid: sched.id }, invert: true } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    elem = json["instance"]["elements"][0]
    assert_equal sched.id, elem["schedRestriction"]["sched"]["unid"]
    assert_equal true, elem["schedRestriction"]["invert"]
  end

  test "GET /doorAccessPriv/list shows schedule in elements" do
    sched = Schedule.create!(name: "Business Hours")
    @ars.door_access_priv_elements.destroy_all
    @ars.door_access_priv_elements.create!(door: @door, schedule: sched, sched_restriction_invert: false)

    get "/doorAccessPriv/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    priv = json["instanceList"].find { |p| p["unid"] == @ars.id }
    elem = priv["elements"][0]
    assert_not_nil elem["schedRestriction"]["sched"]
    assert_equal sched.id, elem["schedRestriction"]["sched"]["unid"]
  end
end
