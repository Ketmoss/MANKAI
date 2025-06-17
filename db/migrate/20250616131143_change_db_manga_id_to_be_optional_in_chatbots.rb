class ChangeDbMangaIdToBeOptionalInChatbots < ActiveRecord::Migration[7.1]
  def change
    change_column_null :chatbots, :db_manga_id, true
  end
end
