class ToolCall < ApplicationRecord
  acts_as_tool_call
  belongs_to :messagebot
end
