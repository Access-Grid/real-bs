require "test_helper"

class Api::DevTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector, address: "192.168.1.1", port: 9000)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @reader = CredReader.create!(name: "Reader 1", sector: @sector, physical_parent: @io_controller)
  end

  # -- Auth enforcement --

  test "GET /dev/list returns 401 without token" do
    get "/dev/list"
    assert_response :unauthorized
  end

  test "POST /dev/save returns 401 without token" do
    post "/dev/save", params: { name: "Test", devType: 1 }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /dev/list returns all device types" do
    get "/dev/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
    assert json["count"] >= 3

    dev_types = json["instanceList"].map { |d| d["devType"] }.uniq.sort
    assert_includes dev_types, 1  # IoController
    assert_includes dev_types, 5  # Door
    assert_includes dev_types, 4  # CredReader
  end

  test "GET /dev/list returns correct translator output per device type" do
    get "/dev/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)

    ctrl = json["instanceList"].find { |d| d["unid"] == @io_controller.id }
    assert_not_nil ctrl
    assert_includes ctrl.keys, "controllerConfig"

    door = json["instanceList"].find { |d| d["unid"] == @door.id }
    assert_not_nil door
    assert_includes door.keys, "doorConfig"

    reader = json["instanceList"].find { |d| d["unid"] == @reader.id }
    assert_not_nil reader
    assert_includes reader.keys, "credReaderConfig"
  end

  test "GET /dev/list supports pagination" do
    get "/dev/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "GET /dev/list includes new Dev base fields" do
    get "/dev/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    ctrl = json["instanceList"].find { |d| d["unid"] == @io_controller.id }
    assert_equal "192.168.1.1", ctrl["address"]
    assert_equal 9000, ctrl["port"]
  end

  # -- Save --

  test "POST /dev/save creates a controller via devType 1" do
    assert_difference "IoController.count", 1 do
      post "/dev/save",
        params: { name: "New Panel", devType: 1, address: "10.0.0.5", port: 8080, devMod: 164 },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["instance"]["devType"]
    assert_equal "New Panel", json["instance"]["name"]
    assert_equal "10.0.0.5", json["instance"]["address"]
    assert_equal 8080, json["instance"]["port"]
    assert_equal 164, json["instance"]["devMod"]
    assert_includes json["instance"].keys, "controllerConfig"
  end

  test "POST /dev/save creates a door via devType 5" do
    assert_difference "Door.count", 1 do
      post "/dev/save",
        params: { name: "New Door", devType: 5 },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 5, json["instance"]["devType"]
    assert_includes json["instance"].keys, "doorConfig"
  end

  test "POST /dev/save creates a sensor via devType 2" do
    assert_difference "Sensor.count", 1 do
      post "/dev/save",
        params: { name: "Door Contact", devType: 2, devUse: 10 },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["instance"]["devType"]
    assert_equal 10, json["instance"]["devUse"]
  end

  test "POST /dev/save returns 422 for missing devType" do
    post "/dev/save",
      params: { name: "No Type" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  test "POST /dev/save returns 422 for invalid devType" do
    post "/dev/save",
      params: { name: "Bad Type", devType: 99 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  test "POST /dev/save with physicalParent ObjRef" do
    post "/dev/save",
      params: { name: "Sub Reader", devType: 4, physicalParent: { unid: @io_controller.id } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @io_controller.id, json["instance"]["physicalParent"]["unid"]
  end

  # -- Update --

  test "POST /dev/update/{id} updates by unid" do
    post "/dev/update/#{@io_controller.id}",
      params: { name: "Updated Panel", address: "10.0.0.99" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Panel", json["instance"]["name"]
    assert_equal "10.0.0.99", json["instance"]["address"]
  end

  test "POST /dev/update/{id} updates by uuid" do
    post "/dev/update/#{@door.uuid}",
      params: { name: "Back Door" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Back Door", @door.reload.name
  end

  test "POST /dev/update/{id} returns 404 for unknown id" do
    post "/dev/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /dev/delete/{id} deletes by unid" do
    assert_difference "Device.count", -1 do
      post "/dev/delete/#{@reader.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /dev/delete/{id} deletes by uuid" do
    assert_difference "Device.count", -1 do
      post "/dev/delete/#{@door.uuid}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /dev/delete/{id} returns 404 for unknown id" do
    post "/dev/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
