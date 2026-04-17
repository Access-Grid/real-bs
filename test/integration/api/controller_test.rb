require "test_helper"

class Api::ControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Main Panel", brand: "Z9", model: "SP-Core", sector: @sector)
  end

  test "GET /controller/list returns 401 without token" do
    get "/controller/list"
    assert_response :unauthorized
  end

  test "POST /controller/save returns 401 without token" do
    post "/controller/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  test "GET /controller/list returns DevListResponse structure" do
    get "/controller/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /controller/list returns controllers with devType 1" do
    get "/controller/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    ctrl = json["instanceList"].find { |c| c["unid"] == @io_controller.id }
    assert_not_nil ctrl
    assert_equal 1, ctrl["devType"]
    assert_equal @io_controller.name, ctrl["name"]
  end

  test "GET /controller/list supports offset and max pagination" do
    IoController.create!(name: "Panel 2", sector: @sector)
    IoController.create!(name: "Panel 3", sector: @sector)

    get "/controller/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "GET /controller/list count reflects total not paginated" do
    count_before = IoController.count
    IoController.create!(name: "Panel 2", sector: @sector)
    get "/controller/list", params: { max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal count_before + 1, json["count"]
    assert_equal 1, json["instanceList"].length
  end

  test "POST /controller/save creates a new controller" do
    assert_difference "IoController.count", 1 do
      post "/controller/save",
        params: { name: "New Panel", metadata: { brand: "HID" } },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["instance"]
    assert_equal "New Panel", json["instance"]["name"]
    assert_equal 1, json["instance"]["devType"]
  end

  test "POST /controller/save returns 422 without name" do
    post "/controller/save",
      params: { metadata: { brand: "HID" } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  test "POST /controller/update/{id} updates by unid" do
    post "/controller/update/#{@io_controller.id}",
      params: { name: "Updated Panel" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Panel", @io_controller.reload.name
  end

  test "POST /controller/update/{id} updates by uuid" do
    post "/controller/update/#{@io_controller.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @io_controller.reload.name
  end

  test "POST /controller/update/{id} returns 404 for unknown id" do
    post "/controller/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  test "POST /controller/delete/{id} deletes by unid" do
    assert_difference "IoController.count", -1 do
      post "/controller/delete/#{@io_controller.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /controller/delete/{id} deletes by uuid" do
    assert_difference "IoController.count", -1 do
      post "/controller/delete/#{@io_controller.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /controller/delete/{id} returns 404 for unknown id" do
    post "/controller/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  test "POST /controller/save with Dev base fields persists them" do
    post "/controller/save",
      params: {
        name: "Net Panel",
        address: "10.0.0.50",
        port: 8080,
        devMod: 164,
        devPlatform: 17,
        externalId: "EXT-NET-1",
        timeZone: "America/Chicago"
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "10.0.0.50", json["instance"]["address"]
    assert_equal 8080, json["instance"]["port"]
    assert_equal 164, json["instance"]["devMod"]
    assert_equal 17, json["instance"]["devPlatform"]
    assert_equal "EXT-NET-1", json["instance"]["externalId"]
    assert_equal "America/Chicago", json["instance"]["timeZone"]
  end

  test "POST /controller/update/{id} updates Dev base fields" do
    post "/controller/update/#{@io_controller.id}",
      params: { address: "10.0.0.99", port: 9999, devMod: 26 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @io_controller.reload
    assert_equal "10.0.0.99", @io_controller.address
    assert_equal 9999, @io_controller.port
    assert_equal 26, @io_controller.dev_mod
  end

  # -- ControllerConfig via API --

  test "POST /controller/save with controllerConfig persists config" do
    post "/controller/save",
      params: {
        name: "Config Panel",
        controllerConfig: { username: "admin", password: "secret123" }
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "admin", json["instance"]["controllerConfig"]["username"]
    assert_equal "secret123", json["instance"]["controllerConfig"]["password"]
  end

  test "GET /controller/list returns controllerConfig" do
    @io_controller.update!(dev_config: { "username" => "user1" })
    get "/controller/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    ctrl = json["instanceList"].find { |c| c["unid"] == @io_controller.id }
    assert_equal "user1", ctrl["controllerConfig"]["username"]
  end

  test "POST /controller/update/{id} updates controllerConfig" do
    post "/controller/update/#{@io_controller.id}",
      params: { controllerConfig: { username: "new_user" } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @io_controller.reload
    assert_equal "new_user", @io_controller.dev_config["username"]
  end

  test "controllers share ID space with other device types" do
    door = Door.create!(name: "Test Door", sector: @sector)
    # Door and controller IDs should not collide -- they're in the same table
    assert_not_equal @io_controller.id, door.id
  end
end
