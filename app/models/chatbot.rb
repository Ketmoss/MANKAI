class Chatbot < ApplicationRecord
  acts_as_chat
  belongs_to :db_manga
  belongs_to :user
  has_many :messagebots, dependent: :destroy


end
