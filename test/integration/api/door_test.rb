require "test_helper"

class Api::DoorTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
  end

  test "GET /door/list returns 401 without token" do
    get "/door/list"
    assert_response :unauthorized
  end

  test "GET /door/list returns doors with devType 5" do
    get "/door/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    door = json["instanceList"].find { |d| d["unid"] == @door.id }
    assert_not_nil door
    assert_equal 5, door["devType"]
    assert_equal @door.name, door["name"]
  end

  test "POST /door/save creates a new door" do
    assert_difference "Door.count", 1 do
      post "/door/save", params: { name: "Back Door" }, headers: { "sessionToken" => @token }, as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Back Door", json["instance"]["name"]
    assert_equal 5, json["instance"]["devType"]
  end

  test "POST /door/update/{id} updates by unid" do
    post "/door/update/#{@door.id}", params: { name: "Side Door" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    assert_equal "Side Door", @door.reload.name
  end

  test "POST /door/update/{id} updates by uuid" do
    post "/door/update/#{@door.uuid}", params: { name: "UUID Door" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    assert_equal "UUID Door", @door.reload.name
  end

  test "POST /door/delete/{id} deletes by unid" do
    assert_difference "Door.count", -1 do
      post "/door/delete/#{@door.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /door/delete/{id} returns 404 for unknown id" do
    post "/door/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- DoorConfig --

  test "POST /door/save with doorConfig stores config" do
    post "/door/save", params: {
      name: "Secure Door",
      doorConfig: {
        username: "admin",
        defaultDoorMode: { staticState: 2, allowCard: true },
        activateStrikeOnRex: true,
        strikeTime: 5000,
        heldTime: 30000
      }
    }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    cfg = json["instance"]["doorConfig"]
    assert_equal "admin", cfg["username"]
    assert_equal({ "staticState" => 2, "allowCard" => true }, cfg["defaultDoorMode"])
    assert_equal true, cfg["activateStrikeOnRex"]
    assert_equal 5000, cfg["strikeTime"]
    assert_equal 30000, cfg["heldTime"]
  end

  test "GET /door/list returns doorConfig" do
    @door.update!(dev_config: { "strikeTime" => 7000, "activateStrikeOnRex" => false })
    get "/door/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    door = json["instanceList"].find { |d| d["unid"] == @door.id }
    assert_equal 7000, door["doorConfig"]["strikeTime"]
    assert_equal false, door["doorConfig"]["activateStrikeOnRex"]
  end

  test "POST /door/update with doorConfig updates config" do
    @door.update!(dev_config: { "strikeTime" => 5000 })
    post "/door/update/#{@door.id}", params: {
      doorConfig: { strikeTime: 7000, extendedStrikeTime: 12000 }
    }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    cfg = json["instance"]["doorConfig"]
    assert_equal 7000, cfg["strikeTime"]
    assert_equal 12000, cfg["extendedStrikeTime"]
  end

  # -- show --

  test "GET /door/show/{id} returns door by unid" do
    get "/door/show/#{@door.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @door.id, json["instance"]["unid"]
    assert_equal @door.name, json["instance"]["name"]
  end

  test "GET /door/show/{id} returns 404 for unknown id" do
    get "/door/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
