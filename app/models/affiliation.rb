# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution
  belongs_to :professor

  validates :start_date, presence: true
  validates :end_date, presence: true, unless: :active?
  validates :active, presence: true, inclusion: { in: [true, false]}

end
