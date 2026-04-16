require "test_helper"

class Api::CredTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ct = CredentialType.create!(name: "Prox Card", kind: "card")
    @group = Group.create!(name: "Staff")
    @person = Person.create!(first_name: "Jane", last_name: "Doe", group: @group)
    @cred = Credential.create!(
      name: "Jane Badge",
      credential_type: @ct,
      person: @person,
      card_pin: { "credNum" => "12345" }
    )
  end

  # -- Auth enforcement --

  test "GET /cred/list returns 401 without token" do
    get "/cred/list"
    assert_response :unauthorized
  end

  test "POST /cred/save returns 401 without token" do
    post "/cred/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /cred/list returns list response structure" do
    get "/cred/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /cred/list returns credentials with Flex fields" do
    get "/cred/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    cred = json["instanceList"].find { |c| c["unid"] == @cred.id }
    assert_not_nil cred
    assert_equal "Jane Badge", cred["name"]
    assert_equal true, cred["enabled"]
    assert_not_nil cred["uuid"]
    assert_equal({ "credNum" => "12345" }, cred["cardPin"])
    assert_equal @ct.id, cred["credTemplate"]["unid"]
    assert_equal @person.id, cred["credHolder"]["unid"]
    assert_equal [], cred["privBindings"]
  end

  test "GET /cred/list supports pagination" do
    Credential.create!(name: "Badge 2")
    Credential.create!(name: "Badge 3")

    get "/cred/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  test "GET /cred/list count reflects total" do
    count_before = Credential.count
    Credential.create!(name: "Badge Extra")
    get "/cred/list", params: { max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal count_before + 1, json["count"]
    assert_equal 1, json["instanceList"].length
  end

  # -- Save --

  test "POST /cred/save creates a credential" do
    assert_difference "Credential.count", 1 do
      post "/cred/save",
        params: { name: "New Badge", cardPin: { credNum: "999" } },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "New Badge", json["instance"]["name"]
    assert_not_nil json["instance"]["uuid"]
  end

  test "POST /cred/save with credTemplate ObjRef" do
    post "/cred/save",
      params: { name: "Linked Badge", credTemplate: { unid: @ct.id } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @ct.id, json["instance"]["credTemplate"]["unid"]
  end

  test "POST /cred/save returns 422 without name" do
    post "/cred/save",
      params: { cardPin: { credNum: "123" } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /cred/update/{id} updates by unid" do
    post "/cred/update/#{@cred.id}",
      params: { name: "Updated Badge" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "Updated Badge", @cred.reload.name
  end

  test "POST /cred/update/{id} updates by uuid" do
    post "/cred/update/#{@cred.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @cred.reload.name
  end

  test "POST /cred/update/{id} returns 404 for unknown id" do
    post "/cred/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /cred/delete/{id} deletes by unid" do
    assert_difference "Credential.count", -1 do
      post "/cred/delete/#{@cred.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /cred/delete/{id} deletes by uuid" do
    assert_difference "Credential.count", -1 do
      post "/cred/delete/#{@cred.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /cred/delete/{id} returns 404 for unknown id" do
    post "/cred/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
