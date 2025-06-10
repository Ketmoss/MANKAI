class UserCollection < ApplicationRecord
  belongs_to :user, dependent: :destroy
  has_many :owned_manga
end
