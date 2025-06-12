class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :user_collections
  has_many :owned_mangas, through: :user_collections
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :chats, dependent: :destroy
end
