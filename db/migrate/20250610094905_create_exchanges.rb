class CreateExchanges < ActiveRecord::Migration[7.1]
  def change
    create_table :exchanges do |t|
      t.string :status
      t.references :user, null: false, foreign_key: true
      t.references :owned_manga, null: false, foreign_key: true

      t.timestamps
    end
  end
end
