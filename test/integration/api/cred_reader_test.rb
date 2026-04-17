require "test_helper"

class Api::CredReaderTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @io_controller = IoController.create!(name: "Panel 1", sector: @sector)
    @door = Door.create!(name: "Front Door", sector: @sector, logical_parent: @io_controller)
    @reader = CredReader.create!(name: "Card Reader 1", sector: @sector, physical_parent: @io_controller, logical_parent: @door)
  end

  test "GET /credReader/list returns 401 without token" do
    get "/credReader/list"
    assert_response :unauthorized
  end

  test "GET /credReader/list returns readers with devType 4" do
    get "/credReader/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    reader = json["instanceList"].find { |r| r["unid"] == @reader.id }
    assert_not_nil reader
    assert_equal 4, reader["devType"]
  end

  test "POST /credReader/save creates a new reader" do
    assert_difference "CredReader.count", 1 do
      post "/credReader/save", params: { name: "New Reader" }, headers: { "sessionToken" => @token }, as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "New Reader", json["instance"]["name"]
    assert_equal 4, json["instance"]["devType"]
  end

  test "POST /credReader/update/{id} updates by unid" do
    post "/credReader/update/#{@reader.id}", params: { name: "Updated Reader" }, headers: { "sessionToken" => @token }, as: :json
    assert_response :success
    assert_equal "Updated Reader", @reader.reload.name
  end

  test "POST /credReader/delete/{id} deletes by unid" do
    assert_difference "CredReader.count", -1 do
      post "/credReader/delete/#{@reader.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credReader/delete/{id} returns 404 for unknown id" do
    post "/credReader/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- CredReaderConfig via API --

  test "POST /credReader/save with credReaderConfig persists config" do
    post "/credReader/save",
      params: {
        name: "OSDP Reader",
        credReaderConfig: { commType: 6, serialPortAddress: "localhost:9843" }
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 6, json["instance"]["credReaderConfig"]["commType"]
    assert_equal "localhost:9843", json["instance"]["credReaderConfig"]["serialPortAddress"]
  end

  test "GET /credReader/list returns credReaderConfig" do
    @reader.update!(dev_config: { "commType" => 6, "serialPortAddress" => "localhost:9843" })
    get "/credReader/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    reader = json["instanceList"].find { |r| r["unid"] == @reader.id }
    assert_equal 6, reader["credReaderConfig"]["commType"]
    assert_equal "localhost:9843", reader["credReaderConfig"]["serialPortAddress"]
  end

  test "POST /credReader/update/{id} updates credReaderConfig" do
    post "/credReader/update/#{@reader.id}",
      params: { credReaderConfig: { commType: 6, tamperType: 2 } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @reader.reload
    assert_equal 6, @reader.dev_config["commType"]
    assert_equal 2, @reader.dev_config["tamperType"]
  end
end
