class GeocodeUsersJob < ApplicationJob
  queue_as :default

  def perform
    User.where(latitude: nil, longitude: nil)
        .where.not(zip_code: [nil, ''])
        .find_each do |user|

      geocoding_result = FrenchGeocoderService.geocode_postal_code(user.zip_code)

      if geocoding_result
        user.update_columns(
          latitude: geocoding_result[:latitude],
          longitude: geocoding_result[:longitude]
        )

        Rails.logger.info "Geocoded user #{user.id} for postal code #{user.zip_code}"
      else
        Rails.logger.warn "Failed to geocode user #{user.id} with postal code #{user.zip_code}"
      end

      # Petite pause pour ne pas surcharger l'API
      sleep(0.1)
    end
  end
end
