class Exchange < ApplicationRecord
  enum status: {
    pending: 0,
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
  after_update :create_chat_if_accepted

  validates :initiator_id, :recipient_id, :wanted_manga_id, presence: true
  validate :validate_different_users

  private
  def validate_different_users
    if initiator_id == recipient_id
      errors.add(:recipient, "ne peut pas être le même que l'initiateur")
    end
  end

  def create_chat_if_accepted
    if status == "accepted" && chat.nil?
      create_chat(user: recipient) # ou initiator, selon ton usage
    end
  end
end
