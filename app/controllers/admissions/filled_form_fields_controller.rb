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

  def download
    record = Admissions::FilledFormField.find params[:id]
    if record.blank? || !request.original_url.end_with?(record.file.url)
      raise ActionController::RoutingError.new("Não encontrado")
    end
    send_data(record.file.read, filename: record.file.filename)
  end
end
