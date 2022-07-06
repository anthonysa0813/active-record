class Critic < ApplicationRecord
  validates :title, :body, presence: true
  validates :title, length: { maximum: 40 }

  belongs_to :user, counter_cache: true
  belongs_to :criticable, polymorphic: true
end
