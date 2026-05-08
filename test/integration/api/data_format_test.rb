require "test_helper"

class Api::DataFormatTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @cf = CredentialFormat.create!(
      name: "26-bit Wiegand",
      data_format_type: 1,
      min_bits: 26,
      max_bits: 26,
      support_reverse_read: false,
      elements: [
        { "type" => "STATIC", "bitIndex" => 0, "value" => 1 },
        { "type" => "FIELD", "name" => "FacilityCode", "bits" => [ 1, 2, 3 ] }
      ]
    )
  end

  # -- Auth enforcement --

  test "GET /dataFormat/list returns 401 without token" do
    get "/dataFormat/list"
    assert_response :unauthorized
  end

  test "POST /binaryFormat/save returns 401 without token" do
    post "/binaryFormat/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List (dataFormat) --

  test "GET /dataFormat/list returns list response structure" do
    get "/dataFormat/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /dataFormat/list returns formats with Flex fields" do
    get "/dataFormat/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    cf = json["instanceList"].find { |c| c["unid"] == @cf.id }
    assert_not_nil cf
    assert_equal "26-bit Wiegand", cf["name"]
    assert_equal 1, cf["dataFormatType"]
    assert_equal 26, cf["minBits"]
    assert_equal 26, cf["maxBits"]
    assert_equal false, cf["supportReverseRead"]
    assert_equal 2, cf["elements"].length
    assert_not_nil cf["uuid"]
  end

  # -- List (binaryFormat alias) --

  test "GET /binaryFormat/list returns same data as /dataFormat/list" do
    get "/binaryFormat/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    cf = json["instanceList"].find { |c| c["unid"] == @cf.id }
    assert_not_nil cf
    assert_equal "26-bit Wiegand", cf["name"]
  end

  # -- Pagination --

  test "GET /dataFormat/list supports pagination" do
    CredentialFormat.create!(name: "Format 2")
    CredentialFormat.create!(name: "Format 3")

    get "/dataFormat/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save (dataFormat) --

  test "POST /dataFormat/save creates a credential format" do
    assert_difference "CredentialFormat.count", 1 do
      post "/dataFormat/save",
        params: {
          name: "37-bit HID",
          dataFormatType: 1,
          minBits: 37,
          maxBits: 37,
          supportReverseRead: true,
          elements: [ { type: "FIELD", name: "CardNumber", bits: [ 1, 2, 3 ] } ]
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "37-bit HID", json["instance"]["name"]
    assert_equal 37, json["instance"]["minBits"]
    assert_not_nil json["instance"]["uuid"]
  end

  # -- Save (binaryFormat alias) --

  test "POST /binaryFormat/save creates a credential format" do
    assert_difference "CredentialFormat.count", 1 do
      post "/binaryFormat/save",
        params: { name: "Custom Binary" },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Custom Binary", json["instance"]["name"]
  end

  test "POST /dataFormat/save returns 422 without name" do
    post "/dataFormat/save",
      params: { minBits: 26 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /dataFormat/update/{id} updates by unid" do
    post "/dataFormat/update/#{@cf.id}",
      params: { name: "Updated Format", minBits: 30 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @cf.reload
    assert_equal "Updated Format", @cf.name
    assert_equal 30, @cf.min_bits
  end

  test "POST /binaryFormat/update/{id} updates by uuid" do
    post "/binaryFormat/update/#{@cf.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @cf.reload.name
  end

  test "POST /dataFormat/update/{id} returns 404 for unknown id" do
    post "/dataFormat/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /dataFormat/delete/{id} deletes by unid" do
    assert_difference "CredentialFormat.count", -1 do
      post "/dataFormat/delete/#{@cf.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /binaryFormat/delete/{id} deletes by uuid" do
    assert_difference "CredentialFormat.count", -1 do
      post "/binaryFormat/delete/#{@cf.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /dataFormat/delete/{id} returns 404 for unknown id" do
    post "/dataFormat/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end

  # -- show --

  test "GET /dataFormat/show/{id} returns data format by unid" do
    get "/dataFormat/show/#{@cf.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @cf.id, json["instance"]["unid"]
    assert_equal @cf.name, json["instance"]["name"]
  end

  test "GET /binaryFormat/show/{id} returns binary format by unid" do
    get "/binaryFormat/show/#{@cf.id}", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @cf.id, json["instance"]["unid"]
  end

  test "GET /dataFormat/show/{id} returns 404 for unknown id" do
    get "/dataFormat/show/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
