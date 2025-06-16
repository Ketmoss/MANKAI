class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true
  after_create_commit -> { broadcast_append_to chat, target: "messages", partial: "messages/message", locals: { message: self, current_user: self.user } }

end
