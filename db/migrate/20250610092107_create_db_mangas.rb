class CreateDbMangas < ActiveRecord::Migration[7.1]
  def change
    create_table :db_mangas do |t|
      t.string :title
      t.string :author
      t.integer :volume
      t.integer :chapter
      t.string :synopsis
      t.string :image_url
      t.string :genre
      t.string :status
      t.integer :jikan_id

      t.timestamps
    end
  end
end
