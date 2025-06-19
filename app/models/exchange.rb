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
  after_update :create_chat_if_accepted, :notify_status_change

  validates :initiator_id, :recipient_id, :wanted_manga_id, presence: true
  validate :validate_different_users

  # Après création, déclencher la notification (sauf si l'auteur commente son propre article)
  after_create_commit :notify_exchange_request

  def message(action)
    case action
    when 'request_created'
      "#{initiator.username} souhaite échanger un de ses mangas contre \"#{wanted_manga.db_manga.title}\""

    when 'request_accepted'
      "#{recipient.username} a accepté ta demande d'échange pour \"#{wanted_manga.db_manga.title}\""

    when 'request_refused'
      "#{recipient.username} a refusé ta demande d'échange pour \"#{wanted_manga.db_manga.title}\""

    when 'exchange_completed'
      "L'échange pour \"#{wanted_manga.db_manga.title}\" a été complété avec succès !"

    else
      "Nouvelle notification concernant un échange"
    end
  end

  def start_time
    meeting_date
  end

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

   # Notification lors de la création d'un échange
  def notify_exchange_request
    ExchangeNotification.with(
      exchange: self,
      recipient: recipient,
      initiator: initiator,
      action: 'request_created',
      manga: wanted_manga,
      message: message('request_created')
    ).deliver_later(recipient)
  end

  # Notification lors du changement de statut
  def notify_status_change
    return unless saved_change_to_status?
    return if initiator == recipient

    case status
    when 'accepted'
      ExchangeNotification.with(
        exchange: self,
        recipient: recipient,
        initiator: initiator,
        action: 'request_accepted',
        manga: wanted_manga,
        message: message('request_accepted')
      ).deliver_later(initiator)

    when 'refused'
      ExchangeNotification.with(
        exchange: self,
        recipient: recipient,
        initiator: initiator,
        action: 'request_refused',
        manga: wanted_manga,
        message: message('request_refused')
      ).deliver_later(initiator)

    when 'completed'
      # Notifier les deux parties
      ExchangeNotification.with(
        exchange: self,
        recipient: recipient,
        initiator: initiator,
        action: 'exchange_completed',
        manga: wanted_manga,
        message: message('exchange_completed')
      ).deliver_later(initiator)

      ExchangeNotification.with(
        exchange: self,
        recipient: recipient,
        initiator: initiator,
        action: 'exchange_completed',
        manga: wanted_manga,
        message: message('exchange_completed')
      ).deliver_later(recipient)
    end
  end
end
