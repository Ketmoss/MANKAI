class UserCollection < ApplicationRecord
  belongs_to :user
  has_many :owned_mangas, dependent: :destroy
end
