# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution
  belongs_to :professor

  validates :start_date, presence: true
  validates :end_date, presence: true, unless: :active?

  validates_uniqueness_of :active, if: :active?, scope: [:professor_id], message: "Apenas uma afiliação pode estar ativa por professor."
end
