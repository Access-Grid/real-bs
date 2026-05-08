require "test_helper"

class Api::NodeDevTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @node_dev = NodeDev.create!(name: "Server Node", sector: @sector)
  end

  test "GET /nodeDev/list returns 401 without token" do
    get "/nodeDev/list"
    assert_response :unauthorized
  end

  test "GET /nodeDev/list returns node devs with devType 0" do
    get "/nodeDev/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    nd = json["instanceList"].find { |n| n["unid"] == @node_dev.id }
    assert_not_nil nd
    assert_equal 0, nd["devType"]
    assert_equal "Server Node", nd["name"]
    assert_not_nil nd["uuid"]
    assert_not_nil nd["nodeDevConfig"]
  end

  test "GET /nodeDev/list supports pagination" do
    NodeDev.create!(name: "Node 2", sector: @sector)
    NodeDev.create!(name: "Node 3", sector: @sector)

    get "/nodeDev/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "POST /nodeDev/save creates a new node dev" do
    assert_difference "NodeDev.count", 1 do
      post "/nodeDev/save", params: { name: "Node 2" }, headers: { "sessionToken" => @token }, as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Node 2", json["instance"]["name"]
    assert_equal 0, json["instance"]["devType"]
  end

  test "POST /nodeDev/save returns 422 without name" do
    post "/nodeDev/save", params: { enabled: true }, headers: { "sessionToken" => @token }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /nodeDev/update/{id} updates by unid" do
    post "/nodeDev/update/#{@node_dev.id}",
      params: { name: "Updated Node" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Node", @node_dev.reload.name
  end

  test "POST /nodeDev/update/{id} updates by uuid" do
    post "/nodeDev/update/#{@node_dev.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @node_dev.reload.name
  end

  test "POST /nodeDev/update/{id} returns 404 for unknown id" do
    post "/nodeDev/update/99999", params: { name: "Nope" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :not_found
  end

  test "POST /nodeDev/delete/{id} deletes by unid" do
    assert_difference "NodeDev.count", -1 do
      post "/nodeDev/delete/#{@node_dev.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /nodeDev/delete/{id} deletes by uuid" do
    assert_difference "NodeDev.count", -1 do
      post "/nodeDev/delete/#{@node_dev.uuid}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /nodeDev/delete/{id} returns 404 for unknown id" do
    post "/nodeDev/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- show --

  test "GET /nodeDev/show/{id} returns node dev by unid" do
    get "/nodeDev/show/#{@node_dev.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @node_dev.id, json["instance"]["unid"]
    assert_equal @node_dev.name, json["instance"]["name"]
  end

  test "GET /nodeDev/show/{id} returns 404 for unknown id" do
    get "/nodeDev/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
