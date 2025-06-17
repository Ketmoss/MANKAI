class AddChatbotToMessagebots < ActiveRecord::Migration[7.1]
  def change
    add_reference :messagebots, :chatbot, null: false, foreign_key: true
  end
end
