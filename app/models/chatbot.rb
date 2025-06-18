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

Si l'utilisateur pose une question précise sur un manga, donne-lui une description personnalisée et adaptée à sa demande, en valorisant le titre, l’auteur, le genre et le résumé.

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
    raw   = user_input.strip
    down  = raw.downcase
    query = GENRE_TRANSLATIONS.fetch(down, raw)

    # 1. Enregistrement du message utilisateur
    messagebots.create!(
      role: "user",
      content: raw,
      db_manga: db_manga.presence
    )

    # --- Extraction mots-clés (avec fallback LLM si vide) ---
    stopwords = %w[
      et un une de du des le la les au aux avec pour par sur dans ce cette cet tu vous as as-tu ton ta tes son sa ses ma mon mes nos votre vos leur leurs on y en a d' l' j' n' s' c'
      aussi mais donc or ni car si quand comme où que quoi qui dont lequel laquelle lesquels lesquelles leur leurs notre votre vos mon ma mes ton ta tes son sa ses notre nos leur leurs
      ici là là-bas maintenant toujours déjà encore tous toutes tout toute alors ainsi après avant depuis depuis peu bientôt tôt tard parfois souvent jamais moins plus mieux
    ]
    keywords = raw.downcase.scan(/\w+/).reject { |w| stopwords.include?(w) || w.length < 3 }

    # -- NOUVEAU : si aucun mot-clé utile, on demande au LLM --
    if keywords.empty?
      keyword_prompt = <<~PROMPT
        Réécris la question suivante en un ou deux mots-clés (genre, thème ou titre de manga), les plus utiles possibles pour une recherche dans une base de données de mangas. Réponds uniquement par les mots-clés séparés par une virgule, sans phrase.
        Question : "#{raw}"
      PROMPT

      llm_resp = RubyLLM.chat(model: model_id || "gpt-4o")
        .with_instructions(keyword_prompt)
        .ask("Quels mots-clés utiliser ?")

      keywords = llm_resp.to_s.downcase.scan(/\w+/)
      # On remet un fallback ultra-safe si vraiment rien n'est remonté
      keywords = [query.downcase] if keywords.empty?
    end

    # Construction dynamique de la requête pour chaque mot-clé
    query_fragments = keywords.map.with_index do |kw, i|
      "(LOWER(title) LIKE :kw#{i} OR LOWER(author) LIKE :kw#{i} OR LOWER(genre) LIKE :kw#{i} OR LOWER(synopsis) LIKE :kw#{i})"
    end.join(" OR ")

    query_params = keywords.each_with_index.map { |kw, i| ["kw#{i}".to_sym, "%#{kw}%"] }.to_h

    matches = DbManga.where(query_fragments, **query_params)
    found_manga = matches.order(Arel.sql('RANDOM()')).first

    if found_manga
      summary = found_manga.synopsis.to_s.strip

      # 2a. Appel LLM pour la présentation
      response_content = begin
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

        if llm_resp.is_a?(String)
          llm_resp
        elsif llm_resp.respond_to?(:content)
          llm_resp.content
        elsif llm_resp.is_a?(Hash)
          llm_resp['content'] || llm_resp[:content]
        else
          llm_resp.to_s
        end

      rescue StandardError => e
        if e.message =~ /Rate limit/i
          Rails.logger.warn("[Chatbot] Rate limit hit, using manual fallback for #{found_manga.title}")
          <<~TEXT
            #{found_manga.title}, écrit par #{found_manga.author}, est un manga de genre #{found_manga.genre}.

            #{summary}

            Qu'en pensez-vous ?
          TEXT
        else
          raise
        end
      end

      # 2c. Sauvegarde et retour
      messagebots.create!(
        role: "assistant",
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
    response_content = case response
                       when String then response
                       when Hash   then response['content'] || response[:content]
                       else            response.respond_to?(:content) ? response.content : response.to_s
                       end

    messagebots.create!(
      role: "assistant",
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
