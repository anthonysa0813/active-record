class InvolvedCompany < ApplicationRecord
  validates :developer, :publisher, inclusion: { in: [true, false]}
  validates :company, uniqueness: { scope: :game, message: "and Game combination alredy taken"}

  belongs_to :company
  belongs_to :game
end
