require "test_helper"

class Api::CredTemplateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ct = CredentialType.create!(
      name: "Prox Card",
      kind: "card",
      frequency: "125kHz",
      protocol: "HID",
      priority: 5,
      card_pin_template: { "credNumPresence" => "REQUIRED" }
    )
  end

  # -- Auth enforcement --

  test "GET /credTemplate/list returns 401 without token" do
    get "/credTemplate/list"
    assert_response :unauthorized
  end

  test "POST /credTemplate/save returns 401 without token" do
    post "/credTemplate/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /credTemplate/list returns list response structure" do
    get "/credTemplate/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /credTemplate/list returns templates with Flex fields" do
    get "/credTemplate/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    ct = json["instanceList"].find { |c| c["unid"] == @ct.id }
    assert_not_nil ct
    assert_equal "Prox Card", ct["name"]
    assert_equal 5, ct["priority"]
    assert_equal "card", ct["kind"]
    assert_equal "125kHz", ct["frequency"]
    assert_equal "HID", ct["protocol"]
    assert_equal({ "credNumPresence" => "REQUIRED" }, ct["cardPinTemplate"])
    assert_not_nil ct["uuid"]
  end

  test "GET /credTemplate/list supports pagination" do
    CredentialType.create!(name: "Type 2")
    CredentialType.create!(name: "Type 3")

    get "/credTemplate/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /credTemplate/save creates a credential type" do
    assert_difference "CredentialType.count", 1 do
      post "/credTemplate/save",
        params: {
          name: "Smart Card",
          priority: 3,
          kind: "card",
          frequency: "13.56MHz",
          protocol: "ISO14443A",
          cardPinTemplate: { credNumPresence: "OPTIONAL" }
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Smart Card", json["instance"]["name"]
    assert_equal 3, json["instance"]["priority"]
    assert_not_nil json["instance"]["uuid"]
  end

  test "POST /credTemplate/save returns 422 without name" do
    post "/credTemplate/save",
      params: { priority: 1 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /credTemplate/update/{id} updates by unid" do
    post "/credTemplate/update/#{@ct.id}",
      params: { name: "Updated Card", priority: 10 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @ct.reload
    assert_equal "Updated Card", @ct.name
    assert_equal 10, @ct.priority
  end

  test "POST /credTemplate/update/{id} updates by uuid" do
    post "/credTemplate/update/#{@ct.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @ct.reload.name
  end

  test "POST /credTemplate/update/{id} returns 404 for unknown id" do
    post "/credTemplate/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /credTemplate/delete/{id} deletes by unid" do
    assert_difference "CredentialType.count", -1 do
      post "/credTemplate/delete/#{@ct.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credTemplate/delete/{id} deletes by uuid" do
    assert_difference "CredentialType.count", -1 do
      post "/credTemplate/delete/#{@ct.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credTemplate/delete/{id} returns 404 for unknown id" do
    post "/credTemplate/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
