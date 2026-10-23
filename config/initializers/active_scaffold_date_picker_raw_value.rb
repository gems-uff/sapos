# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# O bridge date_picker converte o texto enviado e, quando falha, grava nil e
# anota :invalid. Numa linha NOVA de subform has_many, a revalidação antes de
# gravar limpa esse :invalid, o validates_date vê nil (que o allow_blank
# aceita) e a linha grava como período em aberto.
#
# Quando o modelo valida a coluna com validates_timeliness, entregamos o texto
# cru e apagamos o :invalid: quem julga é o modelo, com uma mensagem só. Só se
# o cast do próprio atributo também rejeitar o texto -- o de datetime é
# leniente ("31/02/2026" vira 03/03/2026) e aceitaria uma data que ninguém
# digitou. Fora desses casos, nada muda.
#
# É prepend porque o bridge cria o método por alias_method depois dos
# initializers, e sobrescreveria um def comum.
module ActiveScaffoldDatePickerRawValue
  protected
    def column_value_for_date_picker_type(record, column, value)
      raw_value_on_unparseable_date(super, record, column, value)
    end

    def column_value_for_datetime_picker_type(record, column, value)
      raw_value_on_unparseable_date(super, record, column, value)
    end

  private
    def raw_value_on_unparseable_date(converted, record, column, value)
      return converted unless converted.nil? && value.present? &&
        record.class.validators_on(column.name).any?(ValidatesTimeliness::Validator) &&
        record.class.type_for_attribute(column.name.to_s).cast(value).nil?

      record.errors.delete(column.name, :invalid)
      value
    end
end

ActiveScaffold::AttributeParams.prepend(ActiveScaffoldDatePickerRawValue)
