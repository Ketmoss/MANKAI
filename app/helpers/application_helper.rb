module ApplicationHelper

  def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: "rouge").to_html
  end

  include Pagy::Frontend

    # app/helpers/application_helper.rb (Bootstrap 5 - Rails 7)

# def format_distance(distance)
#   case distance
#   when 0..999
#     "Très proche"
#   when 1000..4999
#     "Proche"
#   when 5000..9999
#     "Moyennement proche"
#   else
#     "Éloigné"
#   end
# end

# def distance_badge_class(distance)
#   case distance
#   when 0..999
#     "badge-success"
#   when 1000..4999
#     "badge-primary"
#   when 5000..9999
#     "badge-warning"
#   else
#     "badge-secondary"
#   end
# end

# Helpers pour les vraies distances avec coordonnées GPS
def calculate_real_distance_km(user1, user2)
  return nil unless user1&.latitude && user1&.longitude && user2&.latitude && user2&.longitude

  FrenchGeocoderService.distance_between_coordinates(
    user1.latitude, user1.longitude,
    user2.latitude, user2.longitude
  )
end

def format_real_distance(user1, user2)
  distance = calculate_real_distance_km(user1, user2)
  return "Distance inconnue" unless distance

  case distance
  when 0..20
    "#{distance} km - Très proche"
  when 20..50
    "#{distance} km - Proche"
  when 50..200
    "#{distance} km - Moyennement proche"
  else
    "#{distance} km - Éloigné"
  end
end

def real_distance_badge_class(user1, user2)
  distance = calculate_real_distance_km(user1, user2)
  return "text-bg-light" unless distance  # Bootstrap 5

  case distance
  when 0..20
    "text-bg-success"    # Bootstrap 5
  when 20..50
    "text-bg-secondary"    # Bootstrap 5
  when 50..200
    "text-bg-warning"    # Bootstrap 5
  else
    "text-bg-primary"  # Bootstrap 5
  end
end
end
