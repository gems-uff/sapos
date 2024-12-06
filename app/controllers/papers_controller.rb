# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PapersController < ApplicationController
  authorize_resource

  active_scaffold :paper do |config|
    config.create.label = :create_paper_label
    config.actions.swap :search, :field_search
    config.list.sorting = { period: "DESC", owner: "ASC", order: "ASC" }

    config.columns.add :header
    config.columns.add :reason_group
    config.columns.add :reason_group_end
    form_columns = [
      :header,
      :period, :owner, :reference, :order, :kind, :doi_issn_event,
      :paper_professors, :paper_students, :other_authors,
      :reason_group,
      :reason_impact_factor,
      :reason_international_list,
      :reason_citations,
      :reason_national_interest,
      :reason_international_interest,
      :reason_national_representativeness,
      :reason_scientific_contribution,
      :reason_tech_contribution,
      :reason_innovation_contribution,
      :reason_social_contribution,
      :reason_other,
      :reason_justify,
      :impact_factor,
      :reason_group_end,
      :other,
    ]
    config.create.columns = form_columns
    config.update.columns = form_columns
    config.show.columns = [
      :period, :owner, :reference, :kind, :doi_issn_event,
      :paper_professors, :paper_students, :other_authors,
      :reason_impact_factor,
      :reason_international_list,
      :reason_citations,
      :reason_national_interest,
      :reason_international_interest,
      :reason_national_representativeness,
      :reason_scientific_contribution,
      :reason_tech_contribution,
      :reason_innovation_contribution,
      :reason_social_contribution,
      :reason_other,
      :reason_justify,
      :impact_factor,
      :order,
      :other,
    ]
    config.list.columns = [
      :period, :owner, :order, :reference
    ]

    config.columns[:owner].form_ui = :record_select
    config.columns[:kind].form_ui = :select
    config.columns[:kind].options = {
      options: Paper::KINDS,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:order].form_ui = :select
    config.columns[:order].options = {
      options: Paper::ORDERS,
      include_blank: I18n.t("active_scaffold._select_")
    }


    config.columns[:paper_students].show_blank_record = false
    config.columns[:paper_professors].show_blank_record = false

    config.actions.exclude :deleted_records
  end

  protected
  def do_new
    super
    @record.period = CustomVariable.quadrennial_period
    unless current_user.professor.blank?
      @record.owner = current_user.professor
    end
  end
end
