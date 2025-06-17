class AddCoordinatesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
    add_index :users, [:latitude, :longitude]
  end
end
