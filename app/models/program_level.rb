# frozen_string_literal: true

class ProgramLevel < ApplicationRecord
  include PeriodConcern

  has_paper_trail

  validates :level, presence: true, on: [:create, :update]
  validates :ordinance, presence: false
  validates :start_date, presence: true, on: [:create, :update]
  validates :end_date, presence: false
  validates_date :end_date, allow_blank: true

  # O programa tem um conceito CAPES por vez. O término é exclusivo, como no
  # on_date. Não há subform: cada conceito é gravado pela própria tela, então a
  # comparação é só com o banco.
  period scope: [], end_inclusive: false

  scope :active, -> { where(end_date: nil) }
  scope :on_date, -> (date) { where("program_levels.start_date <= ? AND (program_levels.end_date > ? OR program_levels.end_date is null)", date, date) }


  def to_label
    "#{I18n.t("activerecord.attributes.program_level.level")} #{level}"
  end

  def to_ordinance
    self.ordinance ? "(#{self.ordinance})" : ""
  end
end
