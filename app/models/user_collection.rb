class UserCollection < ApplicationRecord
  belongs_to :user
  has_many :owned_mangas, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
end
