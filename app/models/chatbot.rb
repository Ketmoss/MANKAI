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
    "romance"         => "romance"
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT
    Tu es un spécialiste des mangas.
    Tu réponds aux questions d'un fan de manga novice.
    Pour aider l'utilisateur à découvrir de nouveaux ouvrages, présente-lui 2 à 3 mangas adaptés à son profil.
    Si l'utilisateur pose une question précise sur un manga, donne-lui une description personnalisée et adaptée à sa demande.
    Donne-lui des informations claires et pertinentes, et réponds toujours en français.
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

    # 2. Recherche dans title, author ou genre
    found_manga = DbManga.where(
      "LOWER(title)  LIKE :q OR LOWER(author) LIKE :q OR LOWER(genre) LIKE :q",
      q: "%#{query.downcase}%"
    ).first

    if found_manga
      summary = found_manga.synopsis.to_s.strip

      # 2a. On tente d'abord l'appel LLM
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

      # 2b. En cas de rate-limit, fallback manuel
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
