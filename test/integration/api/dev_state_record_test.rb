require "test_helper"

class Api::DevStateRecordTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
  end

  test "GET /devStateRecord/list returns 401 without token" do
    get "/devStateRecord/list"
    assert_response :unauthorized
  end

  test "GET /devStateRecord/list returns state records for all devices" do
    get "/devStateRecord/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["count"]
    assert_equal 2, json["instanceList"].size

    record = json["instanceList"].find { |r| r["unid"] == @io_controller.id }
    assert_not_nil record
    assert_equal @io_controller.id, record["dev"]["unid"]
    assert_equal "Controller", record["dev"]["type"]
    assert_not_nil record["devState"]
    assert_equal [], record["devState"]["devAspectStates"]
  end

  test "GET /devStateRecord/list returns door state record with correct type" do
    get "/devStateRecord/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)

    record = json["instanceList"].find { |r| r["unid"] == @door.id }
    assert_not_nil record
    assert_equal "Door", record["dev"]["type"]
  end

  test "GET /devStateRecord/list supports pagination" do
    get "/devStateRecord/list", params: { offset: 0, max: 1 }, headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["count"]
    assert_equal 1, json["instanceList"].size
  end
end
