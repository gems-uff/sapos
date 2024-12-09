# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PaperProfessorsController < ApplicationController
  authorize_resource

  active_scaffold :paper_professor do |config|
    config.create.label = :create_paper_professor_label
    config.columns = [:paper, :professor]
    config.columns[:professor].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
end
