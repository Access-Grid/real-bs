require "test_helper"

class Api::CredReaderTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @building = Building.create!(name: "HQ")
    @sector = Sector.create!(name: "Floor 1", building: @building)
    @ac = AccessController.create!(name: "Panel 1", sector: @sector)
    @ew = EntryWay.create!(name: "Front Door", sector: @sector, access_controller: @ac)
    @reader = Reader.create!(name: "Card Reader 1", access_controller: @ac, entry_way: @ew)
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
    assert_difference "Reader.count", 1 do
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
    assert_difference "Reader.count", -1 do
      post "/credReader/delete/#{@reader.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credReader/delete/{id} returns 404 for unknown id" do
    post "/credReader/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
