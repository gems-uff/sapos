# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class UsersController < ApplicationController
  authorize_resource

  active_scaffold :user do |config|
    config.list.columns = [:email, :name, :roles]
    config.columns = [
      :email, :name, :roles, :professor, :student,
      :password, :password_confirmation
    ]
    config.show.link = nil
    config.create.label = :create_user_label
    config.columns[:roles].form_ui = :select
    config.columns[:password].form_ui = :password
    config.columns[:password_confirmation].form_ui = :password
    config.columns[:professor].form_ui = :record_select
    config.columns[:student].form_ui = :record_select

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name, :email],
    order_by: "name ASC", full_text_search: true
  )

  def before_update_save(record)
    if params[:record][:roles].nil?
      record.roles = []
    end
  end
  def after_update_save(record)
    if record == current_user
      bypass_sign_in(record)
    end
  end
end
