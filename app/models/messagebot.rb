class Messagebot < ApplicationRecord
  acts_as_message
  belongs_to :db_manga, optional: true
  belongs_to :chat, class_name: "Chatbot", foreign_key: "chatbot_id"
  belongs_to :tool_call, optional: true

  validates :content, presence: true
  validates :role, presence: true

  after_create :maybe_generate_chat_title

  def maybe_generate_chat_title
    # Génère un titre pour le chat si c'est le premier message user
    if chat.title.blank? && role == "user" && chat.messagebots.where(role: "user").count == 1
    chat.generate_title_from_first_message
    end
  end
end
