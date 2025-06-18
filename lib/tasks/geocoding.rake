namespace :geocoding do
  desc "Geocode all users with postal codes"
  task users: :environment do
    puts "Starting geocoding of users..."

    users_to_geocode = User.where(latitude: nil, longitude: nil)
                          .where.not(zip_code: [nil, ''])

    puts "Found #{users_to_geocode.count} users to geocode"

    success_count = 0
    error_count = 0

    users_to_geocode.find_each do |user|
      puts "Processing user #{user.id} with postal code: #{user.zip_code}"

      geocoding_result = FrenchGeocoderService.geocode_postal_code(user.zip_code)

      if geocoding_result
        user.update_columns(
          latitude: geocoding_result[:latitude],
          longitude: geocoding_result[:longitude]
        )

        puts "✅ Success: User #{user.id} geocoded to #{geocoding_result[:latitude]}, #{geocoding_result[:longitude]}"
        success_count += 1
      else
        puts "❌ Failed: Could not geocode user #{user.id} with postal code #{user.zip_code}"
        error_count += 1
      end

      # Petite pause pour ne pas surcharger l'API
      sleep(0.2)
    end

    puts "\nGeocoding completed!"
    puts "✅ Success: #{success_count} users"
    puts "❌ Errors: #{error_count} users"
  end

  desc "Test geocoding for a specific postal code"
  task :test, [:postal_code] => :environment do |t, args|
    postal_code = args[:postal_code] || "69001"
    puts "Testing geocoding for postal code: #{postal_code}"

    result = FrenchGeocoderService.geocode_postal_code(postal_code)

    if result
      puts "✅ Success!"
      puts "Latitude: #{result[:latitude]}"
      puts "Longitude: #{result[:longitude]}"
      puts "City: #{result[:city]}"
      puts "Postcode: #{result[:postcode]}"
    else
      puts "❌ Failed to geocode #{postal_code}"
    end
  end

  desc "Show users postal codes"
  task show_users: :environment do
    puts "Users with postal codes:"
    User.where.not(zip_code: [nil, '']).each do |user|
      puts "User #{user.id}: #{user.zip_code} (lat: #{user.latitude}, lon: #{user.longitude})"
    end
  end
end
