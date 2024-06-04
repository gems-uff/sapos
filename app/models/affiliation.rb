# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution
  belongs_to :professor

  validates :start_date, presence: true
  validates :active, presence: true
  validates :end_date, presence: true, unless: :active?

  validates_uniqueness_of :active, if: :active?, scope: [:professor_id], message: "Apenas uma afiliação pode estar ativa por professor."

  def active?
    active
  end

  def date(instant_date)
    Affiliation.where("start_date <= #{instant_date} AND (end_date >= #{instant_date} OR #{active?})")&.last
  end
end
