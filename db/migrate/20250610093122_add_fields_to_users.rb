class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :avatar_url, :string
    add_column :users, :zip_code, :string
    add_column :users, :username, :string
    add_column :users, :rating, :float
  end
end
