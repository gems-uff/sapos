# frozen_string_literal: true

class ProgramLevel < ApplicationRecord
  has_paper_trail
  validates :level, presence: true, on: [:create, :update]
  validates :start_date, presence: true, on: [:create, :update]
  validates :end_date, presence: true, unless: :active?, on: [:create, :update]
  validates_uniqueness_of :active, if: :active?, on: [:create, :update]

  def active?
    active
  end

  def date(instant_date)
    ProgramLevel.where("start_date <= #{instant_date} AND (end_date >= #{instant_date} OR #{active?})")&.last
  end
end
