# app/notifications/exchange_notification.rb
class ExchangeNotification < Noticed::Base
  deliver_by :database

  # Optionnel : ajouter email si souhaité
  # deliver_by :email, mailer: 'ExchangeMailer', method: :exchange_notification

  # Après la livraison, nous diffusons la notification via Turbo Streams
  after_deliver :broadcast_notification

  param :exchange
  param :action
  param :manga
  param :initiator
  param :recipient
  param :message

  def url
    Rails.application.routes.url_helpers.exchange_path(params[:exchange])
  end

  private

  def broadcast_notification
    recipient.broadcast_replace_later_to(
      "notifications_#{recipient.id}_counter",
      target: "notification-counter",
      partial: "notifications/notification_counter",
      locals: { user: recipient }
    )
  end
end
