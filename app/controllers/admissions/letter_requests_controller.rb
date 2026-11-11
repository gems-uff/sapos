# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::LetterRequestsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::LetterRequest" do |config|
    config.columns.add :status
    columns = [
      :access_token, :admission_application, :name, :email, :telephone, :status, :filled_form
    ]

    config.list.columns = columns
    config.show.columns = columns

    # O codigo de acesso e credencial (ver LetterRequestsHelper): a busca e a
    # ordenacao por ele deixariam quem nao o ve confirmar um pedaco de cada
    # vez.
    config.search.columns = [:name, :email, :telephone]
    config.columns[:access_token].sort = false

    config.actions.exclude :deleted_records, :delete, :update, :create, :show
  end
end
