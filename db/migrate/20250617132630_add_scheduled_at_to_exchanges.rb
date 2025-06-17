class AddScheduledAtToExchanges < ActiveRecord::Migration[7.1]
  def change
    add_column :exchanges, :scheduled_at, :datetime
  end
end
