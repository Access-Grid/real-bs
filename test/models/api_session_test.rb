require "test_helper"

class ApiSessionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "testuser", password: "testpass123")
  end

  test "generates session token on create" do
    session = ApiSession.create!(user: @user, expires_at: 24.hours.from_now)
    assert_not_nil session.session_token
    assert_equal 64, session.session_token.length
  end

  test "does not overwrite provided session token" do
    session = ApiSession.create!(user: @user, session_token: "custom_token", expires_at: 24.hours.from_now)
    assert_equal "custom_token", session.session_token
  end

  test "requires expires_at" do
    session = ApiSession.new(user: @user)
    assert_not session.valid?
    assert_includes session.errors[:expires_at], "can't be blank"
  end

  test "session token must be unique" do
    ApiSession.create!(user: @user, session_token: "same_token", expires_at: 24.hours.from_now)
    duplicate = ApiSession.new(user: @user, session_token: "same_token", expires_at: 24.hours.from_now)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:session_token], "has already been taken"
  end

  test "expired? returns true for past expiry" do
    session = ApiSession.create!(user: @user, expires_at: 1.hour.ago)
    assert session.expired?
  end

  test "expired? returns false for future expiry" do
    session = ApiSession.create!(user: @user, expires_at: 1.hour.from_now)
    assert_not session.expired?
  end

  test "active scope excludes expired sessions" do
    active = ApiSession.create!(user: @user, expires_at: 1.hour.from_now)
    expired = ApiSession.create!(user: @user, expires_at: 1.hour.ago)
    assert_includes ApiSession.active, active
    assert_not_includes ApiSession.active, expired
  end
end
