class MessagesController < ApplicationController
  before_action :set_chat
  before_action :authenticate_user!

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user

    if @message.save
      # Broadcast du message via ActionCable
      ChatChannel.broadcast_to(@chat, {
        message: render_to_string(
          partial: 'messages/message_broadcast',
          locals: {
            message: @message,
            sender_id: current_user.id
          },
          formats: [:html]
        ),
        sender_id: current_user.id
      })

      respond_to do |format|
        # Le ChatManager se charge de vider le formulaire via JavaScript
        # Pas besoin de remplacer le formulaire côté serveur
        format.turbo_stream { head :ok }
        format.html { redirect_to chat_path(@chat) }
      end
    else
      # En cas d'erreur, on remplace le formulaire avec les erreurs
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "message-form",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        }
        format.html { render 'chats/show' }
      end
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
