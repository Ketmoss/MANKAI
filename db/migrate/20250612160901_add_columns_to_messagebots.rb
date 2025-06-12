class AddColumnsToMessagebots < ActiveRecord::Migration[7.1]
  def change
    add_column :messagebots, :model_id, :string
    add_column :messagebots, :input_tokens, :integer
    add_column :messagebots, :output_tokens, :integer
    add_reference :messagebots, :tool_call, foreign_key: true
  end
end
