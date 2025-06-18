class AddNotesToOwnedMangas < ActiveRecord::Migration[7.1]
  def change
    add_column :owned_mangas, :notes, :text
  end
end
