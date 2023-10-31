# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormFieldsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FilledFormField" do |config|
    columns = [
      :filled_form, :form_field, :value, :list, :file, :scholarities
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.actions.exclude :deleted_records, :delete, :update, :create
  end
end
