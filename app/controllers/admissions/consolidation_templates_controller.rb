# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ConsolidationTemplatesController < ApplicationController
  authorize_resource :form_template

  active_scaffold "Admissions::FormTemplate" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_form_template_label

    config.list.columns = [:name, :description, :template_type]
    config.create.columns = [:name, :description, :template_type, :fields]
    config.update.columns = [:name, :description, :template_type, :fields]

    config.columns[:fields].show_blank_record = false
    config.columns[:template_type].form_ui = :select
    config.columns[:template_type].options = {
      options: [Admissions::FormTemplate::CONSOLIDATION_FORM]
    }

    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.duplicate.link.method = :get
    config.duplicate.link.position = :after
    config.actions.exclude :deleted_records
  end

  def beginning_of_chain
    super.consolidation
  end

  def self.active_scaffold_controller_for(klass)
    return Admissions::ConsolidationFormFieldsController if klass == Admissions::FormField
    super
  end
end
