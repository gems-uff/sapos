# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module LevelsHelper
  # O :advisement_authorizations padrão usa to_label, que é só o nome do nível:
  # "Mestrado, Mestrado, … (N)", e com o histórico o N conta também os períodos
  # encerrados. Na lista fica o número de credenciamentos vigentes, que era o
  # que o N contava antes do histórico.
  def level_advisement_authorizations_column(record, column)
    record.advisement_authorizations.count { |auth| auth.active_on?(Date.current) }.to_s
  end

  # No show, um período por linha, com orientador. Mesmo molde de
  # professor_advisement_authorizations_show_column.
  def level_advisement_authorizations_show_column(record, options)
    authorizations = record.advisement_authorizations
      .sort_by { |auth| [auth.professor.name.to_s, auth.start_date] }
    return "-" if authorizations.empty?

    body = ""
    count = 0
    authorizations.each do |authorization|
      count += 1
      tr_class = count.even? ? "even-record" : ""
      body += "<tr class=\"record #{tr_class}\">
                <td>#{h(authorization.professor.name)}</td>
                <td>#{date_br(authorization.start_date)}</td>
                <td>#{date_br(authorization.end_date)}</td>
              </tr>"
    end

    resp =
      "<table class=\"showtable listed-records-table\">
        <thead>
          <tr>
            <th>#{I18n.t("activerecord.attributes.advisement_authorization.professor")}</th>
            <th>#{I18n.t("activerecord.attributes.advisement_authorization.start_date")}</th>
            <th>#{I18n.t("activerecord.attributes.advisement_authorization.end_date")}</th>
          </tr>
        </thead>
        <tbody class=\"records\">
        #{body}
        </tbody>
      </table>"
    resp.html_safe
  end
end
