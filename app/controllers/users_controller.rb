# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class UsersController < ApplicationController
  authorize_resource

  active_scaffold :user do |config|
    config.list.columns = [:email, :name, :role]
    config.columns = [:email, :name, :role, :password, :password_confirmation]
    config.show.link = nil
    config.update.label = :update_user_label
    config.create.label = :create_user_label
    config.columns[:role].form_ui = :select
    config.columns[:password].form_ui = :password
    config.columns[:password_confirmation].form_ui = :password

    config.actions.exclude :deleted_records
  end
end