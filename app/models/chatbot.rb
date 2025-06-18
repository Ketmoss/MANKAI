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
    "shonen"          => "shonen"
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

    # 0. Normalisation et traduction du genre si besoin
    raw  = user_input.strip
    down = raw.downcase

    # Extraire et traduire tout genre français présent dans la question
    translated_genres = GENRE_TRANSLATIONS.keys.select { |fr| down.include?(fr) }
    translated        = translated_genres.map { |fr| GENRE_TRANSLATIONS[fr] }

    # Préparer les mots-clés initiaux et ajouter en priorité les traductions
    base_keywords = down.scan(/\w+/)
    keywords      = (translated + base_keywords).uniq

    # 1. Enregistrement du message utilisateur
    messagebots.create!(
      role:    "user",
      content: raw,
      db_manga: db_manga.presence
    )

    # --- Recherche prioritaire par genre (colonne `genre`) ---
    found_manga = nil
    if translated.any?
      ilike   = translated.each_with_index.map { |g, i| "LOWER(genre) LIKE :g#{i}" }.join(" OR ")
      params  = translated.each_with_index.map { |g, i| ["g#{i}".to_sym, "%#{g.downcase}%"] }.to_h
      matches = DbManga.where(ilike, **params)
      found_manga = matches.order(Arel.sql('RANDOM()')).first if matches.exists?
    end

    # --- Fallback : recherche “classique” sur titre/auteur/synopsis ---
    if found_manga.nil?
      keywords.each do |w|
        next unless w.length > 2
        match = DbManga.where("LOWER(title) LIKE ?", "%#{w}%").first
        if match
          found_manga = match
          break
        end
      end
    end

    # --- Si toujours rien, recherche large avec troncature intelligente ---
    if found_manga.nil?
      keywords_truncated = keywords.map { |w| w.length <= 4 ? w : w[0..3] }
      q_fragments = keywords_truncated.map.with_index do |kw, i|
        "(LOWER(title) LIKE :kw#{i} OR LOWER(author) LIKE :kw#{i} OR LOWER(genre) LIKE :kw#{i} OR LOWER(synopsis) LIKE :kw#{i})"
      end.join(" OR ")
      q_params = keywords_truncated.each_with_index.map { |kw, i| ["kw#{i}".to_sym, "%#{kw}%"] }.to_h
      matches = DbManga.where(q_fragments, **q_params)
      found_manga = matches.order(Arel.sql('RANDOM()')).first
    end

    # --- Synonymes via LLM si toujours rien ---
    if found_manga.nil? && keywords.any?
      syn_prompt = <<~PROMPT
        Propose un à trois synonymes ou mots proches pour chaque mot-clé suivant, séparés par des virgules. Uniquement les mots, pas de phrase.
        Mots-clés : #{keywords.join(', ')}
      PROMPT

      llm_resp = RubyLLM.chat(model: model_id || "gpt-4o")
                       .with_instructions(syn_prompt)
                       .ask("Donne les synonymes ou mots associés.")

      new_keywords = llm_resp.to_s.downcase.scan(/\w+/).uniq - stopwords
      keywords_syn = new_keywords.map { |w| w.length <= 4 ? w : w[0..3] }

      unless keywords_syn.empty?
        syn_fragments = keywords_syn.map.with_index do |kw, i|
          "(LOWER(title) LIKE :skw#{i} OR LOWER(author) LIKE :skw#{i} OR LOWER(genre) LIKE :skw#{i} OR LOWER(synopsis) LIKE :skw#{i})"
        end.join(" OR ")
        syn_params = keywords_syn.each_with_index.map { |kw, i| ["skw#{i}".to_sym, "%#{kw}%"] }.to_h
        matches = DbManga.where(syn_fragments, **syn_params)
        found_manga = matches.order(Arel.sql('RANDOM()')).first
      end
    end

    if found_manga
      summary = found_manga.synopsis.to_s.strip

      # Présentation via LLM
      presentation_prompt = <<~PROMPT
        Tu es un spécialiste des mangas.
        Rédige une fiche de présentation claire et engageante en français pour ce manga.
        • Texte brut, sans balises HTML ni Markdown.
        • Organise-le en paragraphes séparés par une ligne vide.
        • Mets en valeur le titre, l’auteur, le genre et le résumé ci-dessous.
        • Termine par une petite question pour inviter à la discussion.

        - Titre  : #{found_manga.title}
        - Auteur : #{found_manga.author}
        - Genre  : #{found_manga.genre}
        - Résumé : #{summary}
      PROMPT

      llm_resp = RubyLLM.chat(model: model_id || "gpt-4o")
                       .with_instructions(presentation_prompt)
                       .ask("Rédige-moi cette fiche.")

      response_content = llm_resp.respond_to?(:content) ? llm_resp.content : llm_resp.to_s

      messagebots.create!(
        role:    "assistant",
        content: response_content,
        db_manga: found_manga
      )
      generate_title_from_first_message if title == "New chat"
      return response_content
    end

    # 3. Flux normal LLM pour les autres requêtes
    manga_context = db_manga.present? ? "Voici le contexte du manga : #{db_manga.synopsis}" : nil
    full_prompt   = [SYSTEM_PROMPT, manga_context].compact.join("\n\n")
    chat          = RubyLLM.chat(model: model_id || "gpt-4o").with_instructions(full_prompt)

    messagebots.order(:created_at)[0...-1].each do |msg|
      next if msg.content.to_s.strip.blank?
      chat.add_message(role: msg.role, content: msg.content.strip)
    end

    response = chat.ask(query)
    response_content = response.respond_to?(:content) ? response.content : response.to_s

    messagebots.create!(
      role:    "assistant",
      content: response_content,
      db_manga: db_manga
    )
    generate_title_from_first_message if title == "New chat"
    response_content

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
