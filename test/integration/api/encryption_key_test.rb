require "test_helper"

class Api::EncryptionKeyTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    @token = JSON.parse(response.body)["sessionToken"]

    @ek = EncryptionKey.create!(
      algorithm: "RSA",
      size: 2048,
      key_identifier: "master-key",
      bytes: "base64encodeddata"
    )
  end

  # -- Auth enforcement --

  test "GET /encryptionKey/list returns 401 without token" do
    get "/encryptionKey/list"
    assert_response :unauthorized
  end

  test "POST /encryptionKey/save returns 401 without token" do
    post "/encryptionKey/save", params: { algorithm: "RSA" }, as: :json
    assert_response :unauthorized
  end

  # -- List --

  test "GET /encryptionKey/list returns list response structure" do
    get "/encryptionKey/list", headers: { "sessionToken" => @token }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "offset"
    assert_includes json.keys, "max"
    assert_includes json.keys, "count"
    assert_includes json.keys, "instanceList"
  end

  test "GET /encryptionKey/list returns keys with Flex fields" do
    get "/encryptionKey/list", headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert json["count"] >= 1
    ek = json["instanceList"].find { |k| k["unid"] == @ek.id }
    assert_not_nil ek
    assert_equal "RSA", ek["algorithm"]
    assert_equal 2048, ek["size"]
    assert_equal "master-key", ek["keyIdentifier"]
    assert_equal "base64encodeddata", ek["bytes"]
    assert_not_nil ek["uuid"]
  end

  test "GET /encryptionKey/list supports pagination" do
    EncryptionKey.create!(algorithm: "AES", size: 256)
    EncryptionKey.create!(algorithm: "AES", size: 128)

    get "/encryptionKey/list", params: { offset: 1, max: 1 }, headers: { "sessionToken" => @token }
    json = JSON.parse(response.body)
    assert_equal 1, json["instanceList"].length
    assert_equal 1, json["offset"]
    assert_equal 1, json["max"]
  end

  # -- Save --

  test "POST /encryptionKey/save creates an encryption key" do
    assert_difference "EncryptionKey.count", 1 do
      post "/encryptionKey/save",
        params: {
          algorithm: "AES",
          size: 256,
          keyIdentifier: "session-key",
          bytes: "aes256bytes"
        },
        headers: { "sessionToken" => @token },
        as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "AES", json["instance"]["algorithm"]
    assert_equal 256, json["instance"]["size"]
    assert_equal "session-key", json["instance"]["keyIdentifier"]
    assert_not_nil json["instance"]["uuid"]
  end

  # -- Update --

  test "POST /encryptionKey/update/{id} updates by unid" do
    post "/encryptionKey/update/#{@ek.id}",
      params: { algorithm: "AES", size: 256 },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    @ek.reload
    assert_equal "AES", @ek.algorithm
    assert_equal 256, @ek.size
  end

  test "POST /encryptionKey/update/{id} updates by uuid" do
    post "/encryptionKey/update/#{@ek.uuid}",
      params: { keyIdentifier: "updated-key" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :success
    assert_equal "updated-key", @ek.reload.key_identifier
  end

  test "POST /encryptionKey/update/{id} returns 404 for unknown id" do
    post "/encryptionKey/update/99999",
      params: { algorithm: "Nope" },
      headers: { "sessionToken" => @token },
      as: :json
    assert_response :not_found
  end

  # -- Delete --

  test "POST /encryptionKey/delete/{id} deletes by unid" do
    assert_difference "EncryptionKey.count", -1 do
      post "/encryptionKey/delete/#{@ek.id}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /encryptionKey/delete/{id} deletes by uuid" do
    assert_difference "EncryptionKey.count", -1 do
      post "/encryptionKey/delete/#{@ek.uuid}", headers: { "sessionToken" => @token }
    end
    assert_response :success
  end

  test "POST /encryptionKey/delete/{id} returns 404 for unknown id" do
    post "/encryptionKey/delete/99999", headers: { "sessionToken" => @token }
    assert_response :not_found
  end
end
