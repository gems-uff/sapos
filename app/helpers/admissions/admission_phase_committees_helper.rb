# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionPhaseCommitteesHelper
  def admission_phase_form_column(record, options)
    record_select_field :admission_phase,
        record.admission_phase || Admissions::AdmissionPhase.new, options
  end

  def admission_committee_form_column(record, options)
    record_select_field :admission_committee,
      record.admission_committee || Admissions::AdmissionCommittee.new, options
  end
end
