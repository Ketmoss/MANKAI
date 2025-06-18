class Chatbot < ApplicationRecord
  acts_as_chat
  belongs_to :db_manga, optional: true
  belongs_to :user
  has_many :messagebots, dependent: :destroy

  # Traduction des genres FR → EN pour les requêtes API
  GENRE_TRANSLATIONS = {
    "aventure"        => "adventure",
    "fantaisie"       => "fantasy",
    "action"          => "action",
    "drame"           => "drama",
    "comédie"         => "comedy",
    "science-fiction" => "science fiction",
    "sf"              => "science fiction",
    "romance"         => "romance",
    "shonen"          => "shonen",
    "ninja"           => "ninja",
    "pirate"          => "pirate",
    "samurai"         => "samurai",
    "yokai"           => "yokai",
    "démon"           => "demon",
    "magie"           => "magic",
    "espace"          => "space",
    "robot"           => "robot",
    "école"           => "school",
    "sports"          => "sports",
    "enquête"         => "mystery",
    "apocalypse"      => "apocalypse",
    "voyage"          => "journey",
    "fantôme"         => "ghost",
    "arts martiaux"   => "martial arts"
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT
    Tu es un spécialiste des mangas.

    Quand tu reçois une question, commence toujours par rechercher en priorité dans la base de données disponible, en te basant sur les mots-clés tapés par l'utilisateur (titre, auteur, genre, etc.).
    Si tu trouves des mangas correspondants dans la base, présente-les en premier à l'utilisateur, en donnant 2 à 3 mangas adaptés à sa demande ou à son profil.
    Si aucun manga n'est trouvé dans la base, alors propose une réponse générale ou des suggestions externes.

    Si l'utilisateur pose une question précise sur un manga, donne-lui une description personnalisée et adaptée à sa demande en priorisant les données de la base de données, en valorisant le titre, l’auteur, le genre et le résumé.

    Rédige toujours des informations claires et pertinentes, en français.
    N’utilise jamais de listes ni de markdown : écris toujours en texte fluide et engageant, en sautant des lignes entre les paragraphes.
    Termine ta réponse par une petite question pour inviter à la discussion.
  PROMPT

  TITLE_PROMPT = <<~PROMPT
    Generate a short, descriptive, 3-to-6-word title that summarizes the user question for a chat conversation.
  PROMPT

  def ask(user_input)
    return nil if user_input.blank?

    raw    = user_input.strip
    down   = raw.downcase

    # Traduction des genres FR
    detected_fr = GENRE_TRANSLATIONS.keys.select { |fr| down.include?(fr) }
    translated  = detected_fr.map { |fr| GENRE_TRANSLATIONS[fr] }

    # Index des mots-clés initiaux
    base_keywords = down.scan(/\w+/)
    keywords      = (translated + base_keywords).uniq

    # Enregistrement du message utilisateur
    messagebots.create!(role: "user", content: raw, db_manga: db_manga.presence)

    # 1. Recherche full-text + trigram via pg_search
    found_manga = nil
    if defined?(DbManga) && DbManga.respond_to?(:search_manga)
      candidate = DbManga.search_manga(raw).first
      found_manga = candidate if candidate.present?
    end

    # 2. En cas d’échec, recherche par genre/synopsis
    if found_manga.nil? && translated.any?
      clauses = translated.each_with_index.map { |g, i|
        "(LOWER(genre) LIKE :g#{i} OR LOWER(synopsis) LIKE :g#{i})"
      }.join(" OR ")
      params = translated.each_with_index.map { |g, i| ["g#{i}".to_sym, "%#{g.downcase}%"] }.to_h
      matches = DbManga.where(clauses, **params)
      found_manga = matches.order(Arel.sql('RANDOM()')).first if matches.exists?
    end

    # 3. Synonymes via LLM si toujours rien
    if found_manga.nil? && keywords.any?
      syn_prompt = <<~PROMPT
        Propose 1 à 3 synonymes pour chaque mot : #{keywords.join(', ')} (séparés par virgule)
      PROMPT
      llm = RubyLLM.chat(model: model_id || "gpt-4o")
                    .with_instructions(syn_prompt)
      resp = llm.ask("Synonymes ?").to_s.downcase.scan(/\w+/)
      syns = resp.uniq - %w[et un une de du des le la les au aux avec pour par sur dans ce cette cet tu vous as as-tu ton ta tes son sa ses ma mon mes nos votre vos leur leurs on y en a d' l' j' n' s' c' aussi mais donc or ni car si quand comme où que quoi qui dont lequel laquelle lesquels lesquelles leur leurs notre votre vos mon ma mes ton ta tes son sa ses notre nos leur leurs ici là là-bas maintenant toujours déjà encore tous toutes tout toute alors ainsi après avant depuis peu bientôt tôt tard parfois souvent jamais moins plus mieux manga mangas salut bonjour bonsoir merci stp svp donne cherche chercher trouve trouver suggère propose propose-moi peux-tu pourrais-tu quel quelle quels quelles que qu’est-ce est-ce où comment pourquoi quand qui anime please give find]
      unless syns.empty?
        clause_syn = syns.map.with_index { |kw,i|
          "(LOWER(title) LIKE :s#{i} OR LOWER(author) LIKE :s#{i} OR LOWER(genre) LIKE :s#{i} OR LOWER(synopsis) LIKE :s#{i})"
        }.join(" OR ")
        params_syn = syns.each_with_index.map { |kw,i| ["s#{i}".to_sym, "%#{kw}%"] }.to_h
        matches   = DbManga.where(clause_syn, **params_syn)
        found_manga = matches.order(Arel.sql('RANDOM()')).first if matches.exists?
      end
    end

    if found_manga
      # Présentation du manga trouvé
      summary = found_manga.synopsis.to_s.strip
      pres_prompt = <<~PROMPT
        Tu es un véritable expert en mangas. Rédige une fiche de présentation en français, en texte fluide (pas de listes ni de markdown), avec :

        🎬 Titre  : #{found_manga.title}
        ✍️ Auteur : #{found_manga.author}
        🏷️ Genre : #{found_manga.genre}
        📖 Résumé : #{summary}

        Intègre un émoji pertinent au début de chaque paragraphe pour renforcer l’émotion ou l’ambiance. Termine ta fiche par une question engageante pour inviter à la discussion.
      PROMPT
      llm = RubyLLM.chat(model: model_id || "gpt-4o")
                    .with_instructions(pres_prompt)
      resp = llm.ask("Fiche ?")
      content = resp.respond_to?(:content) ? resp.content : resp.to_s
      messagebots.create!(role: "assistant", content: content, db_manga: found_manga)
      generate_title_from_first_message if title == "New chat"
      return content
    end

    # 4. Flux normal LLM pour le reste
    manga_ctx = db_manga.present? ? "Voici le contexte : #{db_manga.synopsis}" : nil
    full = [SYSTEM_PROMPT, manga_ctx].compact.join("\n\n")
    chat = RubyLLM.chat(model: model_id || "gpt-4o")
                  .with_instructions(full)
    messagebots.order(:created_at)[0...-1].each do |m|
      next if m.content.blank?
      chat.add_message(role: m.role, content: m.content.strip)
    end
    resp = chat.ask(nil)
    content = resp.respond_to?(:content) ? resp.content : resp.to_s
    messagebots.create!(role: "assistant", content: content, db_manga: db_manga)
    generate_title_from_first_message if title == "New chat"
    content
  rescue => e
    Rails.logger.error("Chatbot#ask failed: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
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
