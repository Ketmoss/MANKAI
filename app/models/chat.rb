class Chat < ApplicationRecord
  belongs_to :exchange
  belongs_to :user
  has_many :messages, dependent: :destroy
end
