class MessagesController < ApplicationController
  before_action :set_chat
  before_action :authenticate_user!

  def create
      @message = @chat.messages.build(message_params)
      @message.user = current_user

      if @message.save
        ChatChannel.broadcast_to(@chat, {
          message: render_to_string(partial: 'messages/message', locals: { message: @message })
        })

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to chat_path(@chat) }
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
