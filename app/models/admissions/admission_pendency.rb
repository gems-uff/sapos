# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPendency < ActiveRecord::Base
  has_paper_trail

  MEMBER = record_i18n_attr("modes.member")
  SHARED = record_i18n_attr("modes.shared")
  MODES = [MEMBER, SHARED]

  PENDENT = record_i18n_attr("statuses.pendent")
  OK = record_i18n_attr("statuses.ok")
  STATUSES = [PENDENT, OK]

  scope :missing_committee, ->(phase_id) {
    where(
      admission_phase_id: phase_id,
      user_id: nil
    )
  }

  scope :pendencies, ->(phase_id, user_id = nil) {
    conditions = {
      admission_phase_id: phase_id,
      status: PENDENT
    }
    if user_id.present?
      conditions[:user_id] = user_id
    end
    where(conditions)
  }


  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"
  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"
  belongs_to :user, optional: true,
    class_name: "User"

  validates :admission_phase_id, uniqueness: { scope: [
    :admission_application_id, :user_id, :mode ] }

  validates :mode, presence: true, inclusion: { in: MODES }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
