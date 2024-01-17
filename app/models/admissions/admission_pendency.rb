# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPendency < ActiveRecord::Base
  has_paper_trail

  MEMBER = record_i18n_attr("modes.member")
  SHARED = record_i18n_attr("modes.shared")
  CANDIDATE = record_i18n_attr("modes.candidate")
  MODES = [MEMBER, SHARED, CANDIDATE]

  PENDENT = record_i18n_attr("statuses.pendent")
  OK = record_i18n_attr("statuses.ok")
  STATUSES = [PENDENT, OK]

  scope :missing_committee, ->(phase_id) {
    where(
      admission_phase_id: phase_id,
      mode: MEMBER,
      status: PENDENT,
      user_id: nil
    )
  }
  scope :member_pendency, ->(phase_id) {
    where(
      admission_phase_id: phase_id,
      mode: MEMBER,
      status: PENDENT,
    ).where.not(
      user_id: nil
    )
  }
  scope :shared_pendency, ->(phase_id) {
    where(
      admission_phase_id: phase_id,
      mode: SHARED,
      status: PENDENT,
    )
  }
  scope :candidate_pendency, ->(phase_id) {
    where(
      admission_phase_id: phase_id,
      mode: CANDIDATE,
      status: PENDENT,
    )
  }

  PENDENCY_QUERIES = {
    member_pendency: "Pendência individual de comitê",
    shared_pendency: "Pendência compartilhada de comitê",
    candidate_pendency: "Pendência de candidato",
    missing_committee: "Com comitê incompleto"
  }

  scope :pendencies, ->(phase_id, user_id = nil, mode = nil) {
    conditions = {
      admission_phase_id: phase_id,
      status: PENDENT
    }
    if user_id.present?
      conditions[:user_id] = user_id
    end
    if mode.present?
      conditions[:mode] = mode
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

  def self.status_value(is_filled)
    is_filled ? OK : PENDENT
  end

  def self.candidate_pendencies(phase, candidate)
    pendency = self.find_or_create_by(
      admission_application_id: candidate.id,
      admission_phase_id: phase.id,
      mode: CANDIDATE
    )
    pendency.update!(status: self.status_value(candidate.results.where(
      admission_phase_id: phase.id,
      mode: Admissions::AdmissionPhaseResult::CANDIDATE,
    ).first.try(:filled_form).try(:is_filled)))
    [pendency]
  end

  def self.member_pendencies(phase, candidate, committee)
    command = {
      admission_application_id: candidate.id,
      admission_phase_id: phase.id,
      mode: MEMBER,
    }
    result = []
    if committee.empty?
      pendency = self.find_or_create_by(command.merge(user_id: nil))
      # If phase has a member form but no committee, it is always pendent
      pendency.update!(status: PENDENT)
      result << pendency
    else
      committee.each do |uid, user|
        pendency = self.find_or_create_by(command.merge(user_id: uid))
        pendency.update!(status: self.status_value(candidate.evaluations.where(
          admission_phase_id: phase.id,
          user_id: uid,
        ).first.try(:filled_form).try(:is_filled)))
        result << pendency
      end
    end
    result
  end

  def self.shared_pendencies(phase, candidate, committee)
    command = {
      admission_application_id: candidate.id,
      admission_phase_id: phase.id,
      mode: SHARED,
    }
    status = self.status_value(candidate.results.where(
      admission_phase_id: phase.id,
      mode: Admissions::AdmissionPhaseResult::SHARED
    ).first.try(:filled_form).try(:is_filled))
    result = []
    if committee.empty?
      pendency = self.find_or_create_by(command.merge(user_id: nil))
      pendency.update!(status:)
      result << pendency
    else
      committee.each do |uid, user|
        pendency = self.find_or_create_by(command.merge(user_id: uid))
        pendency.update!(status:)
        result << pendency
      end
    end
    result
  end
end
