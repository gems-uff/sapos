# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution, optional: true
  belongs_to :professor, optional: true

  validates :start_date, presence: true
  validates :end_date, presence: false
  validates_uniqueness_of :start_date, scope: [:professor_id],
                          allow_nil: true, allow_blank: true,
                          message: "A afiliação só pode ser iniciada em uma data por professor"
  validate :uniqueness_end_date

  scope :on_date, ->(date) { where("start_date <= ? AND (end_date > ? OR end_date IS null)", date, date).last }
  scope :of_professor, ->(professor) { where(professor_id: professor.id) }
  scope :date_professor, ->(professor, date) { of_professor(professor).on_date(date) }

  private

  def uniqueness_end_date
    exists = Affiliation.where(professor_id: professor_id, end_date: end_date).where.not(id: id).exists?
    if exists
      errors.add(:end_date,"Apenas uma afiliação pode estar ativa por professor e só pode ter uma data de fim por professor")
    end
    exists
  end

end
