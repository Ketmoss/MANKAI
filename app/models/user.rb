class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :user_collections
  has_many :owned_mangas, through: :user_collections
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :chats, dependent: :destroy
  has_many :chatbots, dependent: :destroy

  has_many :initiated_exchanges, class_name: "Exchange", foreign_key: :initiator_id
  has_many :received_exchanges, class_name: "Exchange", foreign_key: :recipient_id

  has_many :notifications, as: :recipient, dependent: :destroy

  def can_request_exchange_for?(owned_manga)
    return false if owned_manga.user_collection.user == self
    return false unless owned_manga.available_for_exchange

    # Empêcher plusieurs demandes en double pour le même manga
    Exchange.exists?(
      initiator: self,
      wanted_manga: owned_manga,
      status: [:pending_recipient_response, :awaiting_approval]
    ) == false
  end
  after_save :geocode_postal_code, if: :saved_change_to_zip_code?
  private

  def geocode_postal_code
    return unless zip_code.present?

    geocoding_result = FrenchGeocoderService.geocode_postal_code(zip_code)

    if geocoding_result
      update_columns(
        latitude: geocoding_result[:latitude],
        longitude: geocoding_result[:longitude]
      )
    end
  end
end
