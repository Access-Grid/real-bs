require "test_helper"

class Api::CredHolderTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @cht = CredHolderType.create!(name: "Staff")
    @person = Person.create!(
      first_name: "Jane", last_name: "Doe", title: "Ms.",
      email: "jane@example.com", phone_number: "555-1234",
      cred_holder_type: @cht, custom_text_0: "Badge A"
    )
  end

  # -- Auth enforcement --

  test "GET /credHolder/list returns 401 without token" do
    get "/credHolder/list"
    assert_response :unauthorized
  end

  # -- List --

  test "GET /credHolder/list returns list response structure" do
    get "/credHolder/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /credHolder/list returns cred holders with Flex fields" do
    get "/credHolder/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    ch = json["instanceList"].find { |c| c["unid"] == @person.id }
    assert_not_nil ch
    assert_equal "Jane Doe", ch["name"]
    assert_equal "Jane", ch["first"]
    assert_equal "Doe", ch["last"]
    assert_equal "Ms.", ch["title"]
    assert_equal true, ch["enabled"]
    assert_not_nil ch["uuid"]

    # credHolderType ObjRef
    assert_equal @cht.id, ch["credHolderType"]["unid"]
    assert_equal "Staff", ch["credHolderType"]["name"]

    # emails
    assert_equal 1, ch["emails"].length
    assert_equal "jane@example.com", ch["emails"][0]["emailAddress"]
    assert_equal 0, ch["emails"][0]["type"]

    # phones
    assert_equal 1, ch["phones"].length
    assert_equal "555-1234", ch["phones"][0]["phoneNumber"]
    assert_equal 2, ch["phones"][0]["type"]

    # customData
    assert_equal "Badge A", ch["customData"]["customText0"]
  end

  # -- Show --

  test "GET /credHolder/show/{id} returns by unid" do
    get "/credHolder/show/#{@person.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @person.id, json["instance"]["unid"]
    assert_equal "Jane", json["instance"]["first"]
  end

  test "GET /credHolder/show/{id} returns by uuid" do
    get "/credHolder/show/#{@person.uuid}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @person.id, json["instance"]["unid"]
  end

  test "GET /credHolder/show/{id} returns 404 for unknown id" do
    get "/credHolder/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- Save --

  test "POST /credHolder/save creates a cred holder" do
    assert_difference "Person.count", 1 do
      post "/credHolder/save",
        params: {
          first: "Bob", last: "Smith", title: "Mr.",
          enabled: true,
          credHolderType: { unid: @cht.id },
          emails: [{ type: 0, emailAddress: "bob@example.com" }],
          phones: [{ type: 2, phoneNumber: "555-9999" }],
          customData: { customText0: "Badge B", customText7: "Misc" }
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    inst = json["instance"]
    assert_equal "Bob", inst["first"]
    assert_equal "Smith", inst["last"]
    assert_equal "Mr.", inst["title"]
    assert_not_nil inst["uuid"]
    assert_equal @cht.id, inst["credHolderType"]["unid"]
    assert_equal "bob@example.com", inst["emails"][0]["emailAddress"]
    assert_equal "555-9999", inst["phones"][0]["phoneNumber"]
    assert_equal "Badge B", inst["customData"]["customText0"]
    assert_equal "Misc", inst["customData"]["customText7"]
  end

  test "POST /credHolder/save returns 422 without first name" do
    post "/credHolder/save",
      params: { last: "Smith" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /credHolder/update/{id} updates by unid" do
    post "/credHolder/update/#{@person.id}",
      params: { first: "Janet", title: "Dr." },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @person.reload
    assert_equal "Janet", @person.first_name
    assert_equal "Dr.", @person.title
  end

  test "POST /credHolder/update/{id} updates customData" do
    post "/credHolder/update/#{@person.id}",
      params: { customData: { customText2: "New Value" } },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @person.reload
    assert_equal "New Value", @person.custom_text_2
  end

  test "POST /credHolder/update/{id} returns 404 for unknown id" do
    post "/credHolder/update/99999",
      params: { first: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /credHolder/delete/{id} deletes by unid" do
    assert_difference "Person.count", -1 do
      post "/credHolder/delete/#{@person.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /credHolder/delete/{id} returns 404 for unknown id" do
    post "/credHolder/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
