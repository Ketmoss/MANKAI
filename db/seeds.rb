# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require 'net/http'
require 'json'
require 'uri'

puts "🚀 Début du seeding des mangas depuis Jikan API..."

# Fonction pour faire les requêtes API avec gestion d'erreurs
def fetch_manga_page(page)
  uri = URI("https://api.jikan.moe/v4/manga?page=#{page}&limit=25")

  begin
    response = Net::HTTP.get_response(uri)

    if response.code == '200'
      JSON.parse(response.body)
    else
      puts "❌ Erreur API pour la page #{page}: #{response.code}"
      nil
    end
  rescue => e
    puts "❌ Erreur de connexion pour la page #{page}: #{e.message}"
    nil
  end
end

# Fonction pour créer un manga en base
def create_manga(manga_data)
  # ⚠️ CONDITION: Ne créer le manga que s'il a un titre en anglais
  english_title = manga_data['title_english']

  if english_title.nil? || english_title.strip.empty?
    puts "⏭️  Manga ignoré (pas de titre anglais): #{manga_data['title']}"
    return nil
  end

  # Adaptation selon votre modèle Manga
  # Ajustez les attributs selon votre schema
  DbManga.find_or_create_by(jikan_id: manga_data['mal_id']) do |manga|
    manga.title = english_title
    manga.genre = manga_data['genres'].map { |g| g['name'] }.join(', ')
    manga.synopsis = manga_data['synopsis']&.truncate(1000) # Limiter la taille
    manga.status = manga_data['status']
    manga.author = manga_data['authors'].map { |g| g['name'] }.join(', ')
    manga.chapter = manga_data['chapters']
    manga.volume = manga_data['volumes']
    manga.image_url = manga_data.dig('images', 'jpg', 'large_image_url')
  end
rescue => e
  puts "❌ Erreur lors de la création du manga #{manga_data['title']}: #{e.message}"
  nil
end

# Variables pour le tracking
total_created = 0
total_skipped = 0 # Nouveau compteur pour les mangas ignorés
total_errors = 0
page = 1
max_manga = 1000

puts "📚 Récupération de #{max_manga} mangas avec titre anglais..."

while total_created < max_manga
  puts "📄 Traitement de la page #{page}..."

  # Récupérer les données de la page
  data = fetch_manga_page(page)

  if data.nil?
    total_errors += 1
    page += 1

    # Arrêter après 3 pages d'erreurs consécutives
    if total_errors >= 3
      puts "❌ Trop d'erreurs, arrêt du seeding"
      break
    end

    next
  end

  # Reset du compteur d'erreurs si succès
  total_errors = 0

  # Traiter chaque manga de la page
  mangas = data['data']

  if mangas.empty?
    puts "📭 Aucun manga trouvé sur cette page, fin du seeding"
    break
  end

  mangas.each do |manga_data|
    break if total_created >= max_manga

    manga = create_manga(manga_data)

    if manga.nil?
      # Le manga a été ignoré (pas de titre anglais)
      total_skipped += 1
    elsif manga.persisted?
      total_created += 1
      puts "✅ Manga créé: #{manga.title} (#{total_created}/#{max_manga})"
    end

    # Respecter les limites de l'API (1 requête par seconde)
    sleep(0.1)
  end

  page += 1

  # Pause entre les pages pour respecter l'API
  sleep(1)
end

puts "🎉 Seeding terminé!"
puts "📊 Statistiques:"
puts "   - Mangas créés: #{total_created}"
puts "   - Mangas ignorés (sans titre anglais): #{total_skipped}"
puts "   - Pages traitées: #{page - 1}"

# Afficher quelques stats
if DbManga.count > 0
  puts "\n📈 Aperçu des données:"
  puts "   - Total mangas en base: #{DbManga.count}"
  puts "   - Dernier manga ajouté: #{DbManga.last&.title}"
end

# user1 = User.create!(email: "test@gmail.com", password: "azerty")
# user_collection_test = UserCollection.create!(name: "Shonen",user_id: user1.id)
# OwnedManga.create!(db_manga_id: DbManga.first.id , user_collection_id: user_collection_test.id)

# User.first.owned_mangas.each do |ow|
#   ow.db_manga.title
# end
