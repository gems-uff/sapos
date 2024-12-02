# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class GrantsController < ApplicationController
  authorize_resource

  active_scaffold :grant do |config|
    config.create.label = :create_grant_label
    config.columns = [:title, :start_year, :end_year, :professor, :kind, :funder, :amount]
    config.actions.swap :search, :field_search
    config.columns[:professor].form_ui = :record_select
    config.columns[:kind].form_ui = :select
    config.columns[:kind].options = {
      options: Grant::KINDS,
      default: Grant::PUBLIC,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:amount].options[:format] = :currency
    config.columns[:start_year].options[:format] = "%d"
    config.columns[:end_year].options[:format] = "%d"
    config.actions.exclude :deleted_records
  end

  protected
  def do_new
    super
    unless current_user.professor.blank?
      @record.professor = current_user.professor
    end
  end
end
