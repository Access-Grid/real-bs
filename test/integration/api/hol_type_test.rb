require "test_helper"

class Api::HolTypeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ht = HolidayType.create!(name: "Federal Holiday", external_id: "FED-1")
  end

  # -- Auth enforcement --

  test "GET /holType/list returns 401 without token" do
    get "/holType/list"
    assert_response :unauthorized
  end

  test "POST /holType/save returns 401 without token" do
    post "/holType/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /holType/list returns list response structure" do
    get "/holType/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /holType/list returns holiday types with Flex fields" do
    get "/holType/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    ht = json["instanceList"].find { |h| h["unid"] == @ht.id }
    assert_not_nil ht
    assert_equal "Federal Holiday", ht["name"]
    assert_equal "FED-1", ht["externalId"]
    assert_not_nil ht["uuid"]
  end

  test "GET /holType/list supports pagination" do
    HolidayType.create!(name: "Type 2")
    HolidayType.create!(name: "Type 3")

    get "/holType/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /holType/save creates a holiday type" do
    assert_difference "HolidayType.count", 1 do
      post "/holType/save",
        params: { name: "Company Holiday", externalId: "CO-1" },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Company Holiday", json["instance"]["name"]
    assert_equal "CO-1", json["instance"]["externalId"]
    assert_not_nil json["instance"]["uuid"]
  end

  test "POST /holType/save returns 422 without name" do
    post "/holType/save",
      params: { externalId: "X" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /holType/update/{id} updates by unid" do
    post "/holType/update/#{@ht.id}",
      params: { name: "Updated Type" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Type", @ht.reload.name
  end

  test "POST /holType/update/{id} updates by uuid" do
    post "/holType/update/#{@ht.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @ht.reload.name
  end

  test "POST /holType/update/{id} returns 404 for unknown id" do
    post "/holType/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /holType/delete/{id} deletes by unid" do
    assert_difference "HolidayType.count", -1 do
      post "/holType/delete/#{@ht.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /holType/delete/{id} deletes by uuid" do
    assert_difference "HolidayType.count", -1 do
      post "/holType/delete/#{@ht.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /holType/delete/{id} returns 404 for unknown id" do
    post "/holType/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- show --

  test "GET /holType/show/{id} returns holiday type by unid" do
    get "/holType/show/#{@ht.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @ht.id, json["instance"]["unid"]
    assert_equal @ht.name, json["instance"]["name"]
  end

  test "GET /holType/show/{id} returns 404 for unknown id" do
    get "/holType/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
