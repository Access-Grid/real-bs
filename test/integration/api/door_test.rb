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
end
