# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module UsersHelper
  def user_roles_form_column(record, options)
    roles = Role::ORDER[1..].reverse
    roles.map do |role|
      role_id = "user_role_#{role}"
      content_tag(:label, style: "display:inline-flex;align-items:center;margin-right:12px;", for: role_id) do
        check_box_tag(
          "record[roles][]",
          role,
          record.role_ids.include?(role),
          id: role_id
        ) +
        " #{Role.find_by(id: role).name}"
      end
    end.join.html_safe
  end
end
