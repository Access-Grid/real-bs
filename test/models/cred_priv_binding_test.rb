require "test_helper"

class CredPrivBindingTest < ActiveSupport::TestCase
  test "belongs_to credential" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "ARS")
    binding = CredPrivBinding.create!(credential: cred, access_rule_set: ars)

    assert_equal cred, binding.credential
  end

  test "belongs_to access_rule_set optional" do
    cred = Credential.create!(name: "Badge")
    binding = CredPrivBinding.create!(credential: cred, access_rule_set: nil)

    assert_nil binding.access_rule_set
  end

  test "belongs_to schedule optional" do
    cred = Credential.create!(name: "Badge")
    sched = Schedule.create!(name: "Business Hours")
    binding = CredPrivBinding.create!(credential: cred, schedule: sched)

    assert_equal sched, binding.schedule
  end

  test "dependent destroy from credential" do
    cred = Credential.create!(name: "Badge")
    ars = AccessRuleSet.create!(name: "ARS")
    CredPrivBinding.create!(credential: cred, access_rule_set: ars)

    assert_equal 1, CredPrivBinding.count
    cred.destroy
    assert_equal 0, CredPrivBinding.count
  end

  test "stores dev_as_door_access_priv_unid" do
    cred = Credential.create!(name: "Badge")
    door = Door.create!(name: "Front Door")
    binding = CredPrivBinding.create!(credential: cred, dev_as_door_access_priv_unid: door.id)

    assert_equal door.id, binding.dev_as_door_access_priv_unid
  end

  test "stores sched_restriction_invert" do
    cred = Credential.create!(name: "Badge")
    binding = CredPrivBinding.create!(credential: cred, sched_restriction_invert: true)

    assert_equal true, binding.sched_restriction_invert
  end

  test "sched_restriction_invert defaults to false" do
    cred = Credential.create!(name: "Badge")
    binding = CredPrivBinding.create!(credential: cred)

    assert_equal false, binding.sched_restriction_invert
  end
end
