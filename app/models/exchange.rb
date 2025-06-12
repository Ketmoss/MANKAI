class Exchange < ApplicationRecord
  enum status: {
    pending_recipient_response: 0,
    accepted: 1,
    refused: 2,
    completed: 3,
    cancelled: 4
  }

  belongs_to :initiator, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :wanted_manga, class_name: "OwnedManga"
  belongs_to :offered_manga, class_name: "OwnedManga", optional: true

  has_one :chat, dependent: :destroy

  validates :initiator_id, :recipient_id, :wanted_manga_id, presence: true
  validate :validate_different_users

  def validate_different_users
    if initiator_id == recipient_id
      errors.add(:recipient, "ne peut pas être le même que l'initiateur")
    end
  end
end
