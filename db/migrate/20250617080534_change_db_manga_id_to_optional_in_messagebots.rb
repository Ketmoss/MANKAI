class ChangeDbMangaIdToOptionalInMessagebots < ActiveRecord::Migration[7.1]
  def change
    change_column_null :messagebots, :db_manga_id, true
  end
end
