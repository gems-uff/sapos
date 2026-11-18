# frozen_string_literal: true

class Affiliation < ApplicationRecord
  include PeriodConcern

  has_paper_trail

  belongs_to :institution
  belongs_to :professor

  validates :start_date, presence: true
  validates :end_date, presence: false
  validates_date :end_date, allow_blank: true

  # Um professor não tem duas filiações ao mesmo tempo. O término é exclusivo,
  # como no on_date: a filiação que termina em D e a que começa em D não se
  # cruzam. A regra vale em memória para as linhas do subform de Professor,
  # então encerrar a filiação aberta e abrir a nova cabe num envio só -- a
  # validação anterior lia o banco e exigia dois.
  period scope: [:professor_id],
    parents: { professor: :affiliations },
    end_inclusive: false

  scope :on_date, ->(date) { where("DATE(start_date) <= ? AND (DATE(end_date) > ? OR end_date IS null)", date, date) }
  scope :of_professor, ->(professor) { where(professor_id: professor.id) }
  scope :professor_date, ->(professor, date) { of_professor(professor).on_date(date) }
  scope :active, -> { where(end_date: nil) }
end
