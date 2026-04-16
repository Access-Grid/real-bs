require "test_helper"

class Api::DevActionsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, physical_parent: @io_controller)
  end

  # -- Auth enforcement --

  test "GET /json/doorModeChange returns 401 without token" do
    get "/json/doorModeChange", params: { unid: @door.id, value: "LOCKED" }
    assert_response :unauthorized
  end

  test "GET /json/doorMomentaryUnlock returns 401 without token" do
    get "/json/doorMomentaryUnlock", params: { unid: @door.id }
    assert_response :unauthorized
  end

  # -- doorModeChange --

  test "GET /json/doorModeChange succeeds with valid unid" do
    get "/json/doorModeChange",
      params: { unid: @door.id, value: "LOCKED" },
      headers: { "sessionToken" => @token }
    assert_response :success
  end

  test "GET /json/doorModeChange succeeds with valid uuid" do
    get "/json/doorModeChange",
      params: { uuid: @door.uuid, value: "UNLOCKED" },
      headers: { "sessionToken" => @token }
    assert_response :success
  end

  test "GET /json/doorModeChange returns 404 for unknown device" do
    get "/json/doorModeChange",
      params: { unid: 99999, value: "LOCKED" },
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  test "GET /json/doorModeChange returns 404 with no device params" do
    get "/json/doorModeChange",
      params: { value: "LOCKED" },
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- doorMomentaryUnlock --

  test "GET /json/doorMomentaryUnlock succeeds with valid unid" do
    get "/json/doorMomentaryUnlock",
      params: { unid: @door.id },
      headers: { "sessionToken" => @token }
    assert_response :success
  end

  test "GET /json/doorMomentaryUnlock succeeds with valid uuid" do
    get "/json/doorMomentaryUnlock",
      params: { uuid: @door.uuid },
      headers: { "sessionToken" => @token }
    assert_response :success
  end

  test "GET /json/doorMomentaryUnlock returns 404 for unknown device" do
    get "/json/doorMomentaryUnlock",
      params: { unid: 99999 },
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  test "GET /json/doorMomentaryUnlock accepts optional timing params" do
    get "/json/doorMomentaryUnlock",
      params: { unid: @door.id, strikeTime: 5, heldTime: 30, extDoorTime: true },
      headers: { "sessionToken" => @token }
    assert_response :success
  end
end
