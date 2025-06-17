class Chatbot < ApplicationRecord
  acts_as_chat
  belongs_to :db_manga, optional: true
  belongs_to :user
  has_many :messagebots, dependent: :destroy

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

    # 1. Crée le message utilisateur
    messagebots.create!(
      role: "user",
      content: user_input.strip,
      db_manga: db_manga.presence
    )

    # 2. Recherche dans la base de données
    found_manga = DbManga.where("LOWER(title) LIKE ?", "%#{user_input.downcase}%").first

    if found_manga
      image_html = found_manga.image_url.present? ? "<img src=\"#{found_manga.image_url}\" alt=\"#{found_manga.title}\" style=\"max-width:200px; border-radius:8px; margin-bottom:12px; display:block;\">" : ""

      # Traduction du résumé si besoin
      summary = found_manga.synopsis
      english_words = %w[the and is are with for on in a an to from]
      if summary.present? && english_words.any? { |w| summary.downcase.include?(w) }
        llm_translation_prompt = "Traduis ce texte en français :\n\n#{summary}"

        translation = RubyLLM.chat(model: model_id || "gpt-4o")
          .with_instructions("Réponds uniquement par la traduction du texte en français, sans reformuler.")
          .ask(llm_translation_prompt)

        summary =
          if translation.is_a?(String)
            translation
          elsif translation.is_a?(Hash)
            translation['content'] || translation[:content] || translation.to_s
          elsif translation.respond_to?(:content)
            translation.content
          else
            translation.to_s
          end

        summary = summary.strip if summary.present?
      end

      # Nouveau : Prompt plus strict
      presentation_prompt = <<~PROMPT
        Tu es un spécialiste des mangas.
        Rédige une fiche de présentation claire et engageante en français pour ce manga,
        en intégrant naturellement et en mettant en valeur le titre, l’auteur, le genre et le résumé ci-dessous.
        Commence toujours par l’image (si présente, sinon ignore cette consigne).
        Rédige le texte en plusieurs paragraphes en sautant des lignes (ajoute explicitement un double saut de ligne entre chaque paragraphe).
        N’utilise ni liste ni markdown, fais un texte fluide, sans aucun tiret, et termine par une petite question pour inviter à la discussion.

        Voici les informations :
        - Titre : #{found_manga.title}
        - Auteur : #{found_manga.author}
        - Genre : #{found_manga.genre}
        - Résumé : #{summary}
      PROMPT

      llm_response = RubyLLM.chat(model: model_id || "gpt-4o")
        .with_instructions(presentation_prompt)
        .ask("Rédige-moi cette fiche.")

      final_content =
        if llm_response.is_a?(String)
          llm_response
        elsif llm_response.is_a?(Hash)
          llm_response['content'] || llm_response[:content] || llm_response.to_s
        elsif llm_response.respond_to?(:content)
          llm_response.content
        else
          llm_response.to_s
        end

      # Option : Forcer les doubles retours à la place des simples, si le LLM ne le fait pas bien
      formatted_content = final_content.gsub(/([^\n])\n([^\n])/, '\1<br><br>\2').gsub(/\n{2,}/, '<br><br>')

      # Met l'image AVANT le texte
      response_content = "#{image_html}#{formatted_content}"

      messagebots.create!(
        role: "Light",
        content: response_content,
        db_manga: found_manga
      )

      generate_title_from_first_message if title == "New chat"
      return response_content
    end

    # --- SI RIEN TROUVÉ EN BASE, FLOW LLM COMME AVANT ---
    manga_context = db_manga.present? ? "Voici le contexte du manga : #{db_manga.synopsis}" : nil
    full_prompt = [SYSTEM_PROMPT, manga_context].compact.join("\n\n")

    chat = RubyLLM.chat(model: model_id || "gpt-4o").with_instructions(full_prompt)

    previous_messages = messagebots.order(:created_at)[0...-1]
    previous_messages.each do |msg|
      cleaned_content = msg.content.to_s.strip
      next if cleaned_content.blank?
      chat.add_message(role: msg.role, content: cleaned_content)
    end

    response = chat.ask(user_input.strip)

    response_content = case response
                      when String
                        response
                      when Hash
                        response['content'] || response[:content] || response.to_s
                      else
                        response.respond_to?(:content) ? response.content : response.to_s
                      end

    messagebots.create!(
      role: "Light",
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

    title_content =
      if response.is_a?(String)
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
