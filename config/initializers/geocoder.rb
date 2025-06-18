Geocoder.configure(
  lookup: :nominatim,
  timeout: 5,
  units: :km,
  cache: Rails.cache,
  cache_prefix: 'geocoder:'
)
