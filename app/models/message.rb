class Message < ApplicationRecord
  belongs_to :chat

  belongs_to :user

  validates :content, presence: true

  # Après création, déclencher la notification (sauf si l'auteur commente son propre article)
  after_create_commit :notify_post_user

  private

  def notify_post_user
    return if chat.user == user

    CommentNotification.with(
      message: "#{user.username} t'as envoyé un message"
    ).deliver_later(chat.user)
  end
end
