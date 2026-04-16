require "test_helper"

class Api::HealthTest < ActionDispatch::IntegrationTest
  test "GET /api/health returns 200 with status ok" do
    get "/api/health"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
  end
end
