# frozen_string_literal: true

class UserRolesController < ApplicationController
  skip_authorization_check
  def change_role
    changed_user_role = UserRole.find_by(user: current_user, role_id: params[:role_id])
    if changed_user_role
      current_user.update!(actual_role: changed_user_role.role_id)
      redirect_to root_path, notice: "Role alterado para #{changed_user_role.role.name}."
    else redirect_to root_path, alert: "Role inválido ou não associado ao usuário."
    end
  end
end
