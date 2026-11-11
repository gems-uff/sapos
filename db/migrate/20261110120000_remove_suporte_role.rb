# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# O papel de Suporte sai do sistema (#748). O codigo ja nao conhece o papel 7:
# Role::ORDER nao o tem, e um usuario que continuasse atuando nele quebraria a
# comparacao de papeis da tela de usuarios. Aqui os dados acompanham:
#
# - o vinculo com o papel sai de quem o tem;
# - quem so tinha esse papel passa a Desconhecido;
# - quem atuava como Suporte passa a atuar no maior papel que lhe resta;
# - a linha do papel sai da tabela roles.
#
# Tudo por SQL, sem modelo: os numeros dos papeis estao escritos aqui porque a
# migration nao pode depender de constante que o codigo deixou de ter, e um
# modelo declarado dentro dela entraria em ActiveRecord::Base.descendants de
# quem a carregasse.
class RemoveSuporteRole < ActiveRecord::Migration[8.1]
  SUPORTE = 7
  DESCONHECIDO = 1
  # Role::ORDER sem o Suporte, do menor papel ao maior.
  ORDEM = [1, 5, 4, 3, 2, 6].freeze

  def up
    com_o_papel = select_values("SELECT DISTINCT user_id FROM user_roles WHERE role_id = #{SUPORTE}")
    execute("DELETE FROM user_roles WHERE role_id = #{SUPORTE}")

    atuando = select_values("SELECT id FROM users WHERE actual_role = #{SUPORTE}")
    (com_o_papel | atuando).map(&:to_i).each do |user_id|
      restantes = select_values("SELECT role_id FROM user_roles WHERE user_id = #{user_id}").map(&:to_i)
      if restantes.empty?
        agora = connection.quote(Time.current)
        execute(<<~SQL.squish)
          INSERT INTO user_roles (user_id, role_id, created_at, updated_at)
          VALUES (#{user_id}, #{DESCONHECIDO}, #{agora}, #{agora})
        SQL
        restantes = [DESCONHECIDO]
      end
      maior = restantes.max_by { |papel| ORDEM.index(papel) || -1 }
      execute(<<~SQL.squish)
        UPDATE users SET actual_role = #{maior}
        WHERE id = #{user_id} AND (actual_role = #{SUPORTE} OR actual_role IS NULL)
      SQL
    end

    execute("DELETE FROM roles WHERE id = #{SUPORTE}")
  end

  # Volta a linha do papel, para um codigo anterior que ainda o conheca. Os
  # vinculos nao voltam: a migration nao guarda quem os tinha.
  def down
    return if select_value("SELECT COUNT(*) FROM roles WHERE id = #{SUPORTE}").to_i.positive?

    agora = connection.quote(Time.current)
    execute(<<~SQL.squish)
      INSERT INTO roles (id, name, description, created_at, updated_at)
      VALUES (#{SUPORTE}, 'Suporte', 'Suporte (inserir fotos de alunos)', #{agora}, #{agora})
    SQL
  end
end
