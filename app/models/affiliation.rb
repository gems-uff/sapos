# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  before_save :set_active_default

  belongs_to :institution, optional: true
  belongs_to :professor, optional: true

  validates :start_date, presence: true
  validates :end_date, presence: true, unless: :active?
  validates :end_date, presence: false, if: :active?


  validates_uniqueness_of :active, if: :active?, scope: [:professor_id], message: "Apenas uma afiliação pode estar ativa por professor."

  scope :date, ->(date) { where("start_date <= ? AND (end_date > ? OR active IS TRUE)", date, date) }
  scope :professor, ->(professor) { where(professor_id: professor.id) }
  scope :date_professor, ->(professor, date) { professor(professor).date(date) }
  def active?
    active
  end

  private
    def set_active_default
      self.active = false if active.nil?
    end
end
