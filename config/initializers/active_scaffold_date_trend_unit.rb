# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A busca por data relativa do active_scaffold ("nos ultimos/proximos N dias")
# faz numero.send(unidade) com a unidade que veio do formulario, sem conferir
# contra DATE_UNITS e TIME_UNITS: qualquer metodo, inclusive privado, roda no
# processo. Aqui a unidade fora das listas devolve um intervalo vazio, e
# condition_for_datetime ignora o campo, como qualquer data que nao se le.
#
# Prepend em Finder::ClassMethods, que cada controller recebe por extend
# quando chama active_scaffold. A guarda fica em datetime_from_to, e nao em
# condition_for_datetime: o bridge de datepicker apelida este ultimo
# (alias_method dentro de ClassMethods), e o apelido de um metodo prepended
# perde o super.
module ActiveScaffoldDateTrendUnit
  TREND_OPTIONS = %w[PAST FUTURE].freeze
  UNITS = (ActiveScaffold::Finder::DATE_UNITS + ActiveScaffold::Finder::TIME_UNITS).freeze

  def datetime_from_to(column, value)
    if TREND_OPTIONS.include?(value["opt"]) && !UNITS.include?(value["unit"].to_s.upcase)
      return [nil, nil]
    end
    super
  end
end

ActiveScaffold::Finder::ClassMethods.prepend(ActiveScaffoldDateTrendUnit)
