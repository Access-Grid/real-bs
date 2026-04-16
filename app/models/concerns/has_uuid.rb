module HasUuid
  extend ActiveSupport::Concern

  included do
    validates :uuid, uniqueness: true, allow_nil: true
    before_create :generate_uuid
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
