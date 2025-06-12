class Messagebot < ApplicationRecord
  acts_as_message
  belongs_to :db_manga
  belongs_to :tool_call, optional: true



  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }, if: -> { role == "user" }
  validates :role, presence: true
  validates :chat, presence: true
end
