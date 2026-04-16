require "test_helper"

class Api::AuthenticateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "admin", password: "password123")
  end

  test "POST /authenticate with valid credentials returns authenticated true and sessionToken" do
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal true, json["authenticated"]
    assert_not_nil json["sessionToken"]
    assert json["sessionToken"].length > 0
  end

  test "POST /authenticate returns apiVersion and softwareVersion" do
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    json = JSON.parse(response.body)
    assert_not_nil json["apiVersion"]
    assert_not_nil json["softwareVersion"]
  end

  test "POST /authenticate with apiClientType stores it on session" do
    post "/authenticate", params: { username: "admin", password: "password123", apiClientType: 2 }, as: :json
    json = JSON.parse(response.body)
    assert_equal true, json["authenticated"]
    session = ApiSession.find_by(session_token: json["sessionToken"])
    assert_equal 2, session.api_client_type
  end

  test "POST /authenticate with invalid password returns authenticated false" do
    post "/authenticate", params: { username: "admin", password: "wrongpass" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal false, json["authenticated"]
    assert_nil json["sessionToken"]
  end

  test "POST /authenticate with unknown username returns authenticated false" do
    post "/authenticate", params: { username: "nobody", password: "password123" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal false, json["authenticated"]
  end

  test "returned sessionToken can be used in subsequent requests" do
    post "/authenticate", params: { username: "admin", password: "password123" }, as: :json
    token = JSON.parse(response.body)["sessionToken"]
    assert_not_nil token

    # Token exists as an active session
    session = ApiSession.active.find_by(session_token: token)
    assert_not_nil session
    assert_equal @user.id, session.user_id
  end
end
