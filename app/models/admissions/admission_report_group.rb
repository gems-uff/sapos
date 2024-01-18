# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroup < ActiveRecord::Base
  has_paper_trail

  MAIN = record_i18n_attr("modes.main")
  MAIN_LETTER = record_i18n_attr("modes.main_letter")
  MAIN_ANONYMOUS = record_i18n_attr("modes.main_anonymous")
  FIELD = record_i18n_attr("modes.field")
  LETTER = record_i18n_attr("modes.letter")
  PHASE = record_i18n_attr("modes.phase")
  PHASE_REVERSE = record_i18n_attr("modes.phase_reverse")
  PHASE_WITHOUT_COMMITTEE = record_i18n_attr("modes.phase_without_committee")
  PHASE_WITHOUT_COMMITTEE_REVERSE = record_i18n_attr("modes.phase_without_committee_reverse")
  RANKING = record_i18n_attr("modes.ranking")
  CONSOLIDATION = record_i18n_attr("modes.consolidation")

  MODES = [
    MAIN, MAIN_LETTER, MAIN_ANONYMOUS, FIELD, LETTER,
    PHASE, PHASE_WITHOUT_COMMITTEE, PHASE_REVERSE, PHASE_WITHOUT_COMMITTEE_REVERSE,
    RANKING, CONSOLIDATION
  ]

  INCLUDE = record_i18n_attr("operations.include")
  EXCLUDE = record_i18n_attr("operations.exclude")

  OPERATIONS = [INCLUDE, EXCLUDE]


  LIST = record_i18n_attr("pdf_formats.list")
  TABLE = record_i18n_attr("pdf_formats.table")

  PDF_FORMATS = [LIST, TABLE]

  has_many :columns, dependent: :destroy,
    class_name: "Admissions::AdmissionReportColumn"

  belongs_to :admission_report_config, optional: false,
    class_name: "Admissions::AdmissionReportConfig"

  validates :mode, presence: true, inclusion: { in: MODES }
  validates :pdf_format, presence: true, inclusion: { in: PDF_FORMATS }
  validates :operation, presence: true, inclusion: { in: OPERATIONS }

  def to_label
    "#{self.mode} #{self.operation}"
  end

  def tabular_config(report_config, admission_process, applications)
    extra = {}
    case mode
    when MAIN
      cls = Admissions::AdmissionReportGroupMain
      extra = { fixed: true }
    when MAIN_LETTER
      cls = Admissions::AdmissionReportGroupMain
      extra = { mode: :letter, title: MAIN_LETTER }
    when MAIN_ANONYMOUS
      cls = Admissions::AdmissionReportGroupMain
      extra = { fixed: true, mode: :anonymous, title: MAIN_ANONYMOUS }
    when FIELD
      cls = Admissions::AdmissionReportGroupField
    when LETTER
      cls = Admissions::AdmissionReportGroupLetter
    when PHASE
      cls = Admissions::AdmissionReportGroupPhase
    when PHASE_REVERSE
      cls = Admissions::AdmissionReportGroupPhase
      extra = { reverse: true }
    when PHASE_WITHOUT_COMMITTEE
      cls = Admissions::AdmissionReportGroupPhase
      extra = { hide_committee: true }
    when PHASE_WITHOUT_COMMITTEE_REVERSE
      cls = Admissions::AdmissionReportGroupPhase
      extra = { hide_committee: true, reverse: true }
    when RANKING
      cls = Admissions::AdmissionReportGroupRanking
    when CONSOLIDATION
      cls = Admissions::AdmissionReportGroupConsolidation
    end
    group = cls.new(report_config, self, admission_process, applications, extra)
    group.prepare_config()
    group
  end
end
