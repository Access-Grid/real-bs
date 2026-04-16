require "test_helper"

class Api::DataLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @cf = CredentialFormat.create!(name: "26-bit Wiegand")
    @dl = DataLayout.create!(
      name: "Standard Layout",
      layout_type: 0,
      priority: 5,
      enabled: true,
      data_format: @cf
    )
  end

  # -- Auth enforcement --

  test "GET /dataLayout/list returns 401 without token" do
    get "/dataLayout/list"
    assert_response :unauthorized
  end

  test "POST /basicDataLayout/save returns 401 without token" do
    post "/basicDataLayout/save", params: { name: "Test" }, as: :json
    assert_response :unauthorized
  end

  # -- List (dataLayout) --

  test "GET /dataLayout/list returns list response structure" do
    get "/dataLayout/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /dataLayout/list returns layouts with Flex fields" do
    get "/dataLayout/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    dl = json["instanceList"].find { |d| d["unid"] == @dl.id }
    assert_not_nil dl
    assert_equal "Standard Layout", dl["name"]
    assert_equal 0, dl["layoutType"]
    assert_equal 5, dl["priority"]
    assert_equal true, dl["enabled"]
    assert_not_nil dl["uuid"]
    assert_not_nil dl["dataFormat"]
    assert_equal @cf.id, dl["dataFormat"]["unid"]
    assert_equal "26-bit Wiegand", dl["dataFormat"]["name"]
  end

  # -- List (basicDataLayout alias) --

  test "GET /basicDataLayout/list returns same data as /dataLayout/list" do
    get "/basicDataLayout/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    dl = json["instanceList"].find { |d| d["unid"] == @dl.id }
    assert_not_nil dl
    assert_equal "Standard Layout", dl["name"]
  end

  # -- Pagination --

  test "GET /dataLayout/list supports pagination" do
    DataLayout.create!(name: "Layout 2")
    DataLayout.create!(name: "Layout 3")

    get "/dataLayout/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save (dataLayout) --

  test "POST /dataLayout/save creates a data layout" do
    assert_difference "DataLayout.count", 1 do
      post "/dataLayout/save",
        params: {
          name: "Custom Layout",
          layoutType: 0,
          priority: 3,
          enabled: true,
          dataFormat: { unid: @cf.id }
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Custom Layout", json["instance"]["name"]
    assert_equal 3, json["instance"]["priority"]
    assert_not_nil json["instance"]["uuid"]
    assert_equal @cf.id, json["instance"]["dataFormat"]["unid"]
  end

  # -- Save (basicDataLayout alias) --

  test "POST /basicDataLayout/save creates a data layout" do
    assert_difference "DataLayout.count", 1 do
      post "/basicDataLayout/save",
        params: { name: "Basic Layout" },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Basic Layout", json["instance"]["name"]
  end

  # -- Save with UUID ObjRef --

  test "POST /dataLayout/save resolves dataFormat by uuid" do
    post "/dataLayout/save",
      params: {
        name: "UUID Ref Layout",
        dataFormat: { uuid: @cf.uuid }
      },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @cf.id, json["instance"]["dataFormat"]["unid"]
  end

  test "POST /dataLayout/save returns 422 without name" do
    post "/dataLayout/save",
      params: { priority: 1 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :unprocessable_entity
  end

  # -- Update --

  test "POST /dataLayout/update/{id} updates by unid" do
    post "/dataLayout/update/#{@dl.id}",
      params: { name: "Updated Layout", priority: 10 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @dl.reload
    assert_equal "Updated Layout", @dl.name
    assert_equal 10, @dl.priority
  end

  test "POST /basicDataLayout/update/{id} updates by uuid" do
    post "/basicDataLayout/update/#{@dl.uuid}",
      params: { name: "UUID Updated" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "UUID Updated", @dl.reload.name
  end

  test "POST /dataLayout/update/{id} returns 404 for unknown id" do
    post "/dataLayout/update/99999",
      params: { name: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /dataLayout/delete/{id} deletes by unid" do
    assert_difference "DataLayout.count", -1 do
      post "/dataLayout/delete/#{@dl.id}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /basicDataLayout/delete/{id} deletes by uuid" do
    assert_difference "DataLayout.count", -1 do
      post "/basicDataLayout/delete/#{@dl.uuid}",
        headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /dataLayout/delete/{id} returns 404 for unknown id" do
    post "/dataLayout/delete/99999",
      headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
