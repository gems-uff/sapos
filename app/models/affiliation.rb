# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution
  belongs_to :professor

  validates :start_date, presence: true
  validates :end_date, presence: false
  validates_uniqueness_of :start_date, scope: [:professor_id],
                          allow_nil: true, allow_blank: true,
                          message: "A afiliação só pode ser iniciada em uma data por professor", on: :update
  validate :uniqueness_end_date, on: :update

  scope :on_date, ->(date) { where("DATE(start_date) <= ? AND (DATE(end_date) > ? OR end_date IS null)", date, date) }
  scope :of_professor, ->(professor) { where(professor_id: professor.id) }
  scope :professor_date, ->(professor, date) { of_professor(professor).on_date(date) }
  scope :active, -> { where(end_date: nil) }

  private
    def uniqueness_end_date
      exists = Affiliation.where(professor_id: professor_id, end_date: end_date).where.not(id: id).exists?
      if exists
        errors.add(:end_date,"Apenas uma afiliação pode estar ativa por professor e só pode ter uma data de fim por professor")
      end
      exists
    end

end
