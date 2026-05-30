# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class EmailTemplatesController < ApplicationController
  authorize_resource

  helper :notifications

  active_scaffold :"email_template" do |config|
    config.list.sorting = { name: "ASC" }

    config.create.columns = [:name, :to, :subject, :body, :enabled]
    config.update.columns = [:name, :template_type, :to, :subject, :body, :enabled]
    config.list.columns = [:name, :enabled]

    config.columns[:template_type].form_ui = :select
    config.columns[:template_type].options = {
      options: EmailTemplate::TEMPLATE_TYPES,
    }

    config.create.label = :create_email_template_label

    config.actions.exclude :deleted_records
  end

  def builtin
    result = EmailTemplate.load_template(params[:name])
    respond_to do |format|
      format.json {
        render json: result
      }
    end
  end
end
