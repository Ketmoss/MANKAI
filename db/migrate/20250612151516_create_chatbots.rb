class CreateChatbots < ActiveRecord::Migration[7.1]
  def change
    create_table :chatbots do |t|
      t.string :title
      t.string :model_id
      t.references :db_manga, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
