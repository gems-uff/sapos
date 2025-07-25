# frozen_string_literal: true

class ProgramLevel < ApplicationRecord
  has_paper_trail

  validates :level, presence: true, on: [:create, :update]
  validates :ordinance, presence: false
  validates :start_date, presence: true, on: [:create, :update]
  validates :end_date, presence: false

  scope :active, -> { where(end_date: nil) }
  scope :on_date, -> (date) { where("program_levels.start_date <= ? AND (program_levels.end_date > ? OR program_levels.end_date is null)", date, date)}


  def to_label
    to_ordinance = self.ordinance ? "(#{self.ordinance})" : ""
    "#{I18n.t("activerecord.attributes.program_level.level")} #{level} #{to_ordinance}"
  end

end
