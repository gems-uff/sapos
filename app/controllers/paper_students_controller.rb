# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PaperStudentsController < ApplicationController
  authorize_resource

  active_scaffold :paper_student do |config|
    config.create.label = :create_paper_student_label
    config.columns = [:paper, :student]
    config.columns[:student].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
