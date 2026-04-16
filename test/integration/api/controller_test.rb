require "test_helper"

class Api::ControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @ac = AccessController.create!(name: "Main Panel", brand: "Z9", model: "SP-Core", sector: @sector)
  end

  # -- Authentication enforcement --

  test "GET /controller/list returns 401 without token" do
    get "/controller/list"
    assert_response :unauthorized
  end

  test "POST /controller/save returns 401 without token" do
    post "/controller/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

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
    controller = json["instanceList"].find { |c| c["unid"] == @ac.id }
    assert_not_nil controller
    assert_equal 1, controller["devType"]
    assert_equal @ac.name, controller["name"]
  end

  test "GET /controller/list supports offset and max pagination" do
    AccessController.create!(name: "Panel 2", sector: @sector)
    AccessController.create!(name: "Panel 3", sector: @sector)

    get "/controller/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "GET /controller/list count reflects total not paginated" do
    count_before = AccessController.count
    AccessController.create!(name: "Panel 2", sector: @sector)
    get "/controller/list", params: { max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal count_before + 1, json["count"]
    assert_equal 1, json["instanceList"].length
  end

  # -- Save (create) --

  test "POST /controller/save creates a new controller" do
    assert_difference "AccessController.count", 1 do
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

  # -- Update --

  test "POST /controller/update/{id} updates by unid" do
    post "/controller/update/#{@ac.id}",
      params: { name: "Updated Panel" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Panel", json["instance"]["name"]
    assert_equal "Updated Panel", @ac.reload.name
  end

  test "POST /controller/update/{id} updates by uuid" do
    post "/controller/update/#{@ac.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @ac.reload.name
  end

  test "POST /controller/update/{id} returns 404 for unknown id" do
    post "/controller/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /controller/delete/{id} deletes by unid" do
    assert_difference "AccessController.count", -1 do
      post "/controller/delete/#{@ac.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /controller/delete/{id} deletes by uuid" do
    assert_difference "AccessController.count", -1 do
      post "/controller/delete/#{@ac.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /controller/delete/{id} returns 404 for unknown id" do
    post "/controller/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
