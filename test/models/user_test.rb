require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with username and password" do
    user = User.new(username: "testuser", password: "testpass123")
    assert user.valid?
  end

  test "requires username" do
    user = User.new(password: "testpass123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "requires password" do
    user = User.new(username: "testuser")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "username must be unique" do
    User.create!(username: "testuser", password: "testpass123")
    duplicate = User.new(username: "testuser", password: "otherpass")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
  end

  test "authenticates with correct password" do
    user = User.create!(username: "testuser", password: "testpass123")
    assert user.authenticate("testpass123")
  end

  test "does not authenticate with wrong password" do
    user = User.create!(username: "testuser", password: "testpass123")
    assert_not user.authenticate("wrongpass")
  end
end
