# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

ActiveScaffold.defaults do |config|
  config.security.default_permission = false
  config.ignore_columns.add [
    :created_at, :updated_at, :lock_version, :versions
  ]
  config.create.link.label = :create_link
  config.delete.link.label = ->(_) {
    "<i title='#{I18n.t("active_scaffold.delete_link")}' class='fa fa-trash-o'></i>".html_safe
  }
  config.show.link.label = ->(_) {
    "<i title='#{I18n.t("active_scaffold.show_link")}' class='fa fa-eye'></i>".html_safe
  }
  config.update.link.label = ->(_) {
    "<i title='#{I18n.t("active_scaffold.update_link")}' class='fa fa-pencil'></i>".html_safe
  }
  config.search.link.label = :search_link
  config.delete.link.confirm = :delete_message
  config.search.live = true
end
