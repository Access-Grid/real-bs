require "test_helper"

class Api::CredTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ct = CredentialType.create!(name: "Prox Card")
    @cht = CredHolderType.create!(name: "Staff")
    @person = Person.create!(first_name: "Jane", last_name: "Doe", cred_holder_type: @cht)
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

  # -- doorAccessModifiers --

  test "POST /cred/save with doorAccessModifiers persists them" do
    post "/cred/save",
      params: { name: "ADA Badge", doorAccessModifiers: { extDoorTime: true } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal true, json["instance"]["doorAccessModifiers"]["extDoorTime"]
  end

  test "GET /cred/list returns doorAccessModifiers" do
    @cred.update!(door_access_modifiers: { "extDoorTime" => true })
    get "/cred/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    cred = json["instanceList"].find { |c| c["unid"] == @cred.id }
    assert_equal true, cred["doorAccessModifiers"]["extDoorTime"]
  end

  test "POST /cred/update/{id} updates doorAccessModifiers" do
    post "/cred/update/#{@cred.id}",
      params: { doorAccessModifiers: { extDoorTime: true } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @cred.reload
    assert_equal true, @cred.door_access_modifiers["extDoorTime"]
  end

  # -- privBindings --

  test "POST /cred/save with privBindings creates bindings" do
    ars = AccessRuleSet.create!(name: "All Doors")
    sched = Schedule.create!(name: "Business Hours")

    post "/cred/save",
      params: {
        name: "Priv Badge",
        privBindings: [
          { priv: { unid: ars.id }, schedRestriction: { sched: { unid: sched.id }, invert: true } }
        ]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)

    pbs = json["instance"]["privBindings"]
    assert_equal 1, pbs.length
    assert_equal ars.id, pbs[0]["priv"]["unid"]
    assert_equal sched.id, pbs[0]["schedRestriction"]["sched"]["unid"]
    assert_equal true, pbs[0]["schedRestriction"]["invert"]
  end

  test "GET /cred/list returns privBindings with priv ObjRef" do
    ars = AccessRuleSet.create!(name: "Lobby")
    @cred.cred_priv_bindings.create!(access_rule_set: ars)

    get "/cred/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    cred = json["instanceList"].find { |c| c["unid"] == @cred.id }

    assert_equal 1, cred["privBindings"].length
    assert_equal ars.id, cred["privBindings"][0]["priv"]["unid"]
    assert_equal "Lobby", cred["privBindings"][0]["priv"]["name"]
  end

  test "POST /cred/update with privBindings replaces bindings" do
    ars1 = AccessRuleSet.create!(name: "ARS 1")
    ars2 = AccessRuleSet.create!(name: "ARS 2")
    @cred.cred_priv_bindings.create!(access_rule_set: ars1)

    post "/cred/update/#{@cred.id}",
      params: {
        privBindings: [{ priv: { unid: ars2.id } }]
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)

    pbs = json["instance"]["privBindings"]
    assert_equal 1, pbs.length
    assert_equal ars2.id, pbs[0]["priv"]["unid"]
  end

  test "POST /cred/update without privBindings preserves existing" do
    ars = AccessRuleSet.create!(name: "ARS")
    @cred.cred_priv_bindings.create!(access_rule_set: ars)

    post "/cred/update/#{@cred.id}",
      params: { name: "Renamed Badge" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success

    assert_equal 1, @cred.cred_priv_bindings.reload.count
    assert_equal ars.id, @cred.cred_priv_bindings.first.access_rule_set_id
  end

  test "POST /cred/delete cascades to priv bindings" do
    ars = AccessRuleSet.create!(name: "ARS")
    @cred.cred_priv_bindings.create!(access_rule_set: ars)

    assert_difference "CredPrivBinding.count", -1 do
      post "/cred/delete/#{@cred.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  # -- show --

  test "GET /cred/show/{id} returns credential by unid" do
    get "/cred/show/#{@cred.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @cred.id, json["instance"]["unid"]
    assert_equal @cred.name, json["instance"]["name"]
  end

  test "GET /cred/show/{id} returns 404 for unknown id" do
    get "/cred/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
