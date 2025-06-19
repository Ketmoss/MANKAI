class Chatbot < ApplicationRecord
  acts_as_chat
  belongs_to :db_manga, optional: true
  belongs_to :user
  has_many :messagebots, dependent: :destroy

  GENRE_TRANSLATIONS = {
    # Aventure & Action
  "aventure"         => "adventure",
  "voyage"           => "journey",
  "action"           => "action",
  "arts martiaux"    => "martial arts",
  "ninja"            => "ninja",
  "pirate"           => "pirate",
  "samurai"          => "samurai",
  # Fantastique & Surnaturel
  "fantaisie"        => "fantasy",
  "magie"            => "magic",
  "démon"            => "demon",
  "fantôme"          => "ghost",
  "yokai"            => "yokai",
  # Science-fiction & Tech
  "science-fiction"  => "science fiction",
  "sf"               => "science fiction",
  "espace"           => "space",
  "robot"            => "robot",
  "apocalypse"       => "apocalypse",
  # Vie scolaire & Tranche de vie
  "école"            => "school",
  "slice of life"    => "slice of life",
  # Romance & Drame
  "romance"          => "romance",
  "amour"            => "love",
  "drame"            => "drama",
  # Comédie
  "comédie"          => "comedy",
  "humour"           => "comedy",
  # Sport
  "sport"            => "sports",
  "sports"           => "sports", # pour tolérance orthographique
  # Enquête / Mystère / Thriller
  "enquête"          => "mystery",
  "mystère"          => "mystery",
  "thriller"         => "thriller",
  # Démographies manga
  "shonen"           => "shonen",
  "shojo"            => "shojo",
  "seinen"           => "seinen",
  "josei"            => "josei"
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT
  Tu es un expert manga.
  À chaque question, recherche d'abord dans la base (titre, auteur, genre, synopsis).
  Si tu trouves un manga correspondant, présente-le en priorité.
  Sinon, propose une réponse générale ou des ressources externes.
  Pour une demande précise sur un manga, puise dans la base et valorise titre, auteur, genre et résumé.
  Lors de la présentation, limite le résumé à 350 caractères maximum.
  Toujours en français, texte fluide (pas de listes/markdown), avec un saut de ligne entre les paragraphes.
  Termine par une question pour engager la discussion.
  PROMPT

  TITLE_PROMPT = <<~PROMPT
    Generate a short, descriptive, 3-to-6-word title that summarizes the user question for a chat conversation.
  PROMPT

  def ask(user_input)
    return nil if user_input.blank?

    raw = user_input.strip
    down = raw.downcase

    detected_fr = GENRE_TRANSLATIONS.keys.select { |fr| down.include?(fr) }
    translated = detected_fr.map { |fr| GENRE_TRANSLATIONS[fr] }

    base_keywords = down.scan(/\w+/)
    keywords = (translated + base_keywords).uniq

    messagebots.create!(role: "user", content: raw, db_manga: db_manga.presence)

    found_manga = nil
    if defined?(DbManga) && DbManga.respond_to?(:search_manga)
      candidates = DbManga.search_manga(raw).with_pg_search_rank.order(pg_search_rank: :desc).limit(3)
      found_manga = candidates.first if candidates.exists?
    end

    found_manga ||= DbManga.find_by("LOWER(title) = ?", raw.downcase)

    if found_manga.nil? && translated.any?
      clauses = translated.each_with_index.map { |g, i|
        "(genre ILIKE :g#{i} OR synopsis ILIKE :g#{i})"
      }.join(" OR ")
      params = translated.each_with_index.map { |g, i| ["g#{i}".to_sym, "%#{g}%"] }.to_h
      matches = DbManga.where(clauses, **params)
      found_manga = matches.order(Arel.sql('RANDOM()')).first if matches.exists?
    end

    if found_manga
      summary = found_manga.synopsis.to_s.strip
      pres_prompt = <<~PROMPT
      Tu es un véritable expert en mangas. Rédige une fiche de présentation en français, en texte fluide (pas de listes ni de markdown), avec :
      🎬 Titre  : #{found_manga.title}
      ✍️ Auteur : #{found_manga.author}
      🏷️ Genre  : #{found_manga.genre}
      📖 Résumé : #{summary}
      Le résumé doit faire **350 caractères maximum**. Commence par un emoji adapté et termine par une question engageante.
      PROMPT
      llm = RubyLLM.chat(model: model_id || "gpt-4o").with_instructions(pres_prompt)
      resp = llm.ask("Fiche ?")
      content = resp.respond_to?(:content) ? resp.content : resp.to_s
      messagebots.create!(role: "assistant", content: content, db_manga: found_manga)
      generate_title_from_first_message if title == "New chat"
      return content
    end

    chat = RubyLLM.chat(model: model_id || "gpt-4o").with_instructions(SYSTEM_PROMPT)
    resp = chat.ask(nil)
    content = resp.respond_to?(:content) ? resp.content : resp.to_s
    messagebots.create!(role: "assistant", content: content, db_manga: db_manga)
    generate_title_from_first_message if title == "New chat"
    content
  rescue => e
    Rails.logger.error("Chatbot#ask failed: #{e.message}")
    nil
  end

  def generate_title_from_first_message
    first_user_message = messagebots.where(role: "user").order(:created_at).first
    return if first_user_message.nil? || first_user_message.content.blank?
    return unless title.blank?

    response = RubyLLM.chat
                      .with_instructions(TITLE_PROMPT)
                      .ask(first_user_message.content.strip)

    title_content = if response.is_a?(String)
      response
    elsif response.is_a?(Hash)
      response['content'] || response[:content] || response.to_s
    elsif response.respond_to?(:content)
      response.content
    else
      response.to_s
    end

    title_content = title_content.strip.truncate(60, omission: "...") if title_content.present?
    update(title: title_content) if title_content.present?
  rescue => e
    Rails.logger.error("Title generation failed: #{e.message}")
  end
end
