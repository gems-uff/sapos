# frozen_string_literal: true

class UserRolesController < ApplicationController
  skip_authorization_check
  authorize_resource

  skip_authorize_resource only: :change_role

  active_scaffold :user_role do |config|
    config.list.columns = [:user, :role]
    config.search.columns = [:user, :role]
    config.columns[:user].search_sql = "users.name"
    config.columns[:role].search_sql = "roles.name"
    config.columns[:user].sort_by sql: "users.name"
    config.columns[:role].sort_by sql: "roles.name"

    config.actions.exclude :create, :update, :delete, :deleted_records
  end

  def change_role
    changed_user_role = UserRole.find_by(user: current_user, role_id: params[:role_id])
    if changed_user_role
      current_user.update!(actual_role: changed_user_role.role_id)
      redirect_to root_path, notice: "Role alterado para #{changed_user_role.role.name}."
    else redirect_to root_path, alert: "Role inválido ou não associado ao usuário."
    end
  end
end
