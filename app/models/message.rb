class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true
  after_create_commit -> { broadcast_append_to chat, target: "messages", partial: "messages/message", locals: { message: self, current_user: self.user } }


  def sent_by_current_user?(current_user)
    user == current_user
  end

  # Après création, déclencher la notification (sauf si l'auteur commente son propre article)
  after_create_commit :notify_post_user

  private

def notify_post_user
  # Trouver l'autre utilisateur dans le chat via les messages
  other_user = chat.messages.where.not(user_id: user.id).last&.user || chat.user

  return if other_user == user

  CommentNotification.with(
    message: "#{user.username} t'a envoyé un message"
  ).deliver_later(other_user)
end
end
