# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  before_save :set_active_default

  belongs_to :institution, optional: true
  belongs_to :professor, optional: true

  validates :start_date, presence: true
  validates :end_date, presence: true, if: :active?

  validates_uniqueness_of :active, if: :active?, scope: [:professor_id], message: "Apenas uma afiliação pode estar ativa por professor."

  def active?
    active
  end

  def date(instant_date)
    Affiliation.where("start_date <= #{instant_date} AND (end_date >= #{instant_date} OR #{active?})")&.last
  end

  private
    def set_active_default
      self.active = false if active.nil?
    end
end
