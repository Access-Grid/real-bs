class ApiSession < ApplicationRecord
  belongs_to :user

  validates :session_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_session_token, on: :create

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.hex(32)
  end
end
