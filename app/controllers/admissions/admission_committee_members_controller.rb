# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionCommitteeMembersController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionCommitteeMember" do |config|
    config.create.label = :create_admission_committee_member_label
    columns = [:admission_committee, :user]

    config.columns = columns

    config.columns[:admission_committee].form_ui = :record_select
    config.columns[:user].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
