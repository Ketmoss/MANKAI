class CreateMessagebots < ActiveRecord::Migration[7.1]
  def change
    create_table :messagebots do |t|
      t.string :role
      t.text :content
      t.references :db_manga, null: false, foreign_key: true

      t.timestamps
    end
  end
end
