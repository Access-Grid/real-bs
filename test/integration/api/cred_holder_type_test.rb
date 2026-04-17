require "test_helper"

class Api::CredHolderTypeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @cht = CredHolderType.create!(name: "Staff", tag: "s1")
  end

  # -- Auth enforcement --

  test "GET /credHolderType/list returns 401 without token" do
    get "/credHolderType/list"
    assert_response :unauthorized
  end

  # -- List --

  test "GET /credHolderType/list returns list response structure" do
    get "/credHolderType/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /credHolderType/list returns cred holder types with Flex fields" do
    get "/credHolderType/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    cht = json["instanceList"].find { |c| c["unid"] == @cht.id }
    assert_not_nil cht
    assert_equal "Staff", cht["name"]
    assert_not_nil cht["uuid"]
    assert_equal "s1", cht["tag"]
  end

  # -- Show --

  test "GET /credHolderType/show/{id} returns by unid" do
    get "/credHolderType/show/#{@cht.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @cht.id, json["instance"]["unid"]
    assert_equal "Staff", json["instance"]["name"]
  end

  test "GET /credHolderType/show/{id} returns 404 for unknown id" do
    get "/credHolderType/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- Save --

  test "POST /credHolderType/save creates a cred holder type" do
    assert_difference "CredHolderType.count", 1 do
      post "/credHolderType/save",
        params: { name: "Visitors" },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Visitors", json["instance"]["name"]
    assert_not_nil json["instance"]["uuid"]
  end

  test "POST /credHolderType/save returns 422 without name" do
    post "/credHolderType/save",
      params: { tag: "no-name" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /credHolderType/update/{id} updates by unid" do
    post "/credHolderType/update/#{@cht.id}",
      params: { name: "Updated Staff" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Staff", @cht.reload.name
  end

  test "POST /credHolderType/update/{id} returns 404 for unknown id" do
    post "/credHolderType/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /credHolderType/delete/{id} deletes by unid" do
    assert_difference "CredHolderType.count", -1 do
      post "/credHolderType/delete/#{@cht.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credHolderType/delete/{id} returns 404 for unknown id" do
    post "/credHolderType/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
