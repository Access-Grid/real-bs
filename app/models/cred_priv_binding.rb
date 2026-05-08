class CredPrivBinding < ApplicationRecord
  belongs_to :credential
  belongs_to :access_rule_set, optional: true
  belongs_to :schedule, optional: true
end
