class UserCollection < ApplicationRecord
  belongs_to :user, dependent: :destroy
  has_many :owned_mangas, dependent: :destroy
end
