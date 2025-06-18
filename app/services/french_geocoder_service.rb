# app/services/french_geocoder_service.rb (version alternative)
class FrenchGeocoderService
  include HTTParty

  def self.geocode_postal_code(postal_code)
    return nil if postal_code.blank?

    begin
      clean_postal_code = postal_code.to_s.strip.gsub(/\s+/, '')
      Rails.logger.info "Geocoding postal code: #{clean_postal_code}"

      # Méthode 1: API Geo (plus fiable pour les codes postaux)
      result = geocode_with_geo_api(clean_postal_code)
      return result if result

      # Méthode 2: API Adresse en fallback
      result = geocode_with_address_api(clean_postal_code)
      return result if result

      Rails.logger.warn "All geocoding methods failed for: #{clean_postal_code}"
      nil

    rescue => e
      Rails.logger.error "Geocoding error for #{postal_code}: #{e.message}"
      nil
    end
  end

  private

  def self.geocode_with_geo_api(postal_code)
    Rails.logger.info "Trying API Geo for #{postal_code}"

    response = HTTParty.get("https://geo.api.gouv.fr/communes", {
      query: {
        codePostal: postal_code,
        fields: 'centre,nom,codesPostaux'
      },
      timeout: 10
    })

    Rails.logger.info "API Geo response: #{response.code}"
    Rails.logger.debug "API Geo body: #{response.parsed_response}"

    if response.success? && response.parsed_response.is_a?(Array) && response.parsed_response.any?
      commune = response.parsed_response.first

      if commune['centre'] && commune['centre']['coordinates']
        coordinates = commune['centre']['coordinates'] # [longitude, latitude]

        result = {
          latitude: coordinates[1].to_f,
          longitude: coordinates[0].to_f,
          city: commune['nom'],
          postcode: postal_code
        }

        Rails.logger.info "API Geo success for #{postal_code}: #{result}"
        return result
      end
    end

    nil
  end

  def self.geocode_with_address_api(postal_code)
    Rails.logger.info "Trying API Adresse for #{postal_code}"

    # Essayer plusieurs requêtes
    queries = [
      { q: postal_code, type: 'municipality' },
      { q: postal_code },
      { postcode: postal_code }
    ]

    queries.each_with_index do |query_params, index|
      Rails.logger.info "API Adresse attempt #{index + 1}: #{query_params}"

      response = HTTParty.get("https://api-adresse.data.gouv.fr/search/", {
        query: query_params.merge(limit: 1),
        timeout: 10
      })

      Rails.logger.info "API Adresse attempt #{index + 1} response: #{response.code}"

      if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['features']&.any?
        feature = response.parsed_response['features'].first
        coordinates = feature['geometry']['coordinates']

        result = {
          latitude: coordinates[1].to_f,
          longitude: coordinates[0].to_f,
          city: feature['properties']['city'] || feature['properties']['name'],
          postcode: postal_code
        }

        Rails.logger.info "API Adresse success for #{postal_code}: #{result}"
        return result
      end
    end

    nil
  end

  def self.distance_between_coordinates(lat1, lon1, lat2, lon2)
    return 0 if lat1 == lat2 && lon1 == lon2

    rad_per_deg = Math::PI / 180
    rkm = 6371

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (rkm * c).round(1)
  end
end
