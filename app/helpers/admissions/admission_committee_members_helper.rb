# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionCommitteeMembersHelper
  def user_form_column(record, options)
    record_select_field :user, record.user || User.new, options
  end

  def admission_committee_form_column(record, options)
    record_select_field :admission_committee,
      record.admission_committee || Admissions::AdmissionCommittee.new, options
  end
end
