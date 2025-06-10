class CreateOwnedMangas < ActiveRecord::Migration[7.1]
  def change
    create_table :owned_mangas do |t|
      t.boolean :available, default: true
      t.string :state
      t.references :user_collection, null: false, foreign_key: true
      t.references :db_manga, null: false, foreign_key: true

      t.timestamps
    end
  end
end
