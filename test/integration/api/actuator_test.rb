require "test_helper"

class Api::ActuatorTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @actuator = Actuator.create!(name: "Door Strike", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "GET /actuator/list returns 401 without token" do
    get "/actuator/list"
    assert_response :unauthorized
  end

  test "GET /actuator/list returns actuators with devType 3" do
    get "/actuator/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    act = json["instanceList"].find { |a| a["unid"] == @actuator.id }
    assert_not_nil act
    assert_equal 3, act["devType"]
    assert_equal "Door Strike", act["name"]
    assert_not_nil act["uuid"]
    assert_not_nil act["actuatorConfig"]
  end

  test "GET /actuator/list supports pagination" do
    Actuator.create!(name: "Act 2", sector: @sector)
    Actuator.create!(name: "Act 3", sector: @sector)

    get "/actuator/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "POST /actuator/save creates a new actuator" do
    assert_difference "Actuator.count", 1 do
      post "/actuator/save", params: { name: "Relay Output" }, headers: { "sessionToken" => @token }, as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Relay Output", json["instance"]["name"]
    assert_equal 3, json["instance"]["devType"]
  end

  test "POST /actuator/save returns 422 without name" do
    post "/actuator/save", params: { enabled: true }, headers: { "sessionToken" => @token }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /actuator/update/{id} updates by unid" do
    post "/actuator/update/#{@actuator.id}",
      params: { name: "Updated Strike" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Strike", @actuator.reload.name
  end

  test "POST /actuator/update/{id} updates by uuid" do
    post "/actuator/update/#{@actuator.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @actuator.reload.name
  end

  test "POST /actuator/update/{id} returns 404 for unknown id" do
    post "/actuator/update/99999", params: { name: "Nope" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :not_found
  end

  test "POST /actuator/delete/{id} deletes by unid" do
    assert_difference "Actuator.count", -1 do
      post "/actuator/delete/#{@actuator.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /actuator/delete/{id} deletes by uuid" do
    assert_difference "Actuator.count", -1 do
      post "/actuator/delete/#{@actuator.uuid}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /actuator/delete/{id} returns 404 for unknown id" do
    post "/actuator/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
