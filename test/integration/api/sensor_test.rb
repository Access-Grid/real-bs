require "test_helper"

class Api::SensorTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @sensor = Sensor.create!(name: "Door Contact", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "GET /sensor/list returns 401 without token" do
    get "/sensor/list"
    assert_response :unauthorized
  end

  test "GET /sensor/list returns sensors with devType 2" do
    get "/sensor/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    sensor = json["instanceList"].find { |s| s["unid"] == @sensor.id }
    assert_not_nil sensor
    assert_equal 2, sensor["devType"]
  end

  test "POST /sensor/save creates a new sensor" do
    assert_difference "Sensor.count", 1 do
      post "/sensor/save", params: { name: "REX Sensor" }, headers: { "sessionToken" => @token }, as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "REX Sensor", json["instance"]["name"]
    assert_equal 2, json["instance"]["devType"]
  end

  test "POST /sensor/update/{id} updates by unid" do
    post "/sensor/update/#{@sensor.id}", params: { name: "Updated Sensor" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    assert_equal "Updated Sensor", @sensor.reload.name
  end

  test "POST /sensor/delete/{id} deletes by unid" do
    assert_difference "Sensor.count", -1 do
      post "/sensor/delete/#{@sensor.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /sensor/delete/{id} returns 404 for unknown id" do
    post "/sensor/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- SensorConfig via API --

  test "POST /sensor/save with sensorConfig persists invert" do
    post "/sensor/save",
      params: { name: "Inverted Sensor", sensorConfig: { invert: true } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal true, json["instance"]["sensorConfig"]["invert"]
  end

  test "GET /sensor/list returns sensorConfig" do
    @sensor.update!(dev_config: { "invert" => true })
    get "/sensor/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    sensor = json["instanceList"].find { |s| s["unid"] == @sensor.id }
    assert_equal true, sensor["sensorConfig"]["invert"]
  end

  test "POST /sensor/update/{id} updates sensorConfig" do
    post "/sensor/update/#{@sensor.id}",
      params: { sensorConfig: { invert: true } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @sensor.reload
    assert_equal true, @sensor.dev_config["invert"]
  end

  # -- show --

  test "GET /sensor/show/{id} returns sensor by unid" do
    get "/sensor/show/#{@sensor.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @sensor.id, json["instance"]["unid"]
    assert_equal @sensor.name, json["instance"]["name"]
  end

  test "GET /sensor/show/{id} returns 404 for unknown id" do
    get "/sensor/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
