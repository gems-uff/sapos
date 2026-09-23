# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# As duas consultas de credenciados que os seeds instalam contavam qualquer
# linha de advisement_authorizations. Com o credenciamento virando período,
# elas passam a exigir vigência na data de hoje, com o mesmo predicado de
# AdvisementAuthorization.on_date. Editar o seed só alcança instalação nova;
# esta migration leva o SQL novo às que já existem.
#
# "Hoje" no SQL é CURRENT_DATE, que segue o fuso da sessão do banco (no SQLite,
# sempre UTC), e não o config.time_zone da aplicação. No dia exato em que um
# credenciamento começa ou termina, a consulta pode discordar do seletor de
# orientador por algumas horas.
#
# Só é reescrita a consulta cujo texto ainda é o que algum seed gravou. As
# variantes vêm do histórico do seed: a de CRLF (até 7.15.23) difere da de LF
# só na quebra de linha, que a comparação normaliza; a "Professores
# credenciados" trocou aspas duplas por simples em 7.15.35. Consulta editada
# pela tela é da instalação: fica como está e é listada, para ser revista à mão.
#
# Grava com update_column: o Query valida executando o SQL, e regravar um texto
# não precisa rodar a consulta de cada instalação. Que o SQL novo executa é
# coberto pelo seeds:check do CI, em MariaDB, que grava o mesmo texto pelo seed.
class FilterAccreditationValidityInSeededQueries < ActiveRecord::Migration[7.1]
  STUDENTS_PER_PROFESSOR = "Número de alunos por professor credenciado e nível"
  ACCREDITED_PROFESSORS = "Professores credenciados"

  STUDENTS_PER_PROFESSOR_OLD = <<~SQL
    SELECT p.name as "professor",
           l.name as "nível",
           COUNT(DISTINCT(e.id)) as "orientandos"
    FROM advisement_authorizations aa, professors p, advisements a, levels l, enrollments e
    WHERE aa.professor_id = p.id
    AND p.id = a.professor_id
    AND a.enrollment_id = e.id
    AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
    AND e.level_id = l.id
    GROUP BY p.name, l.name
  SQL

  STUDENTS_PER_PROFESSOR_NEW = <<~SQL
    SELECT p.name as "professor",
           l.name as "nível",
           COUNT(DISTINCT(e.id)) as "orientandos"
    FROM advisement_authorizations aa, professors p, advisements a, levels l, enrollments e
    WHERE aa.professor_id = p.id
    AND DATE(aa.start_date) <= CURRENT_DATE
    AND (aa.end_date IS NULL OR DATE(aa.end_date) >= CURRENT_DATE)
    AND p.id = a.professor_id
    AND a.enrollment_id = e.id
    AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
    AND e.level_id = l.id
    GROUP BY p.name, l.name
  SQL

  ACCREDITED_PROFESSORS_OLD_DOUBLE_QUOTES = <<~SQL
    SELECT DISTINCT CONCAT("1", REPLACE(REPLACE(p.cpf, ".", ""), "-", "")), p.email, p.name
    FROM advisement_authorizations aa, professors p
    WHERE aa.professor_id = p.id
    ORDER BY p.name
  SQL

  ACCREDITED_PROFESSORS_OLD = <<~SQL
    SELECT DISTINCT CONCAT('1', REPLACE(REPLACE(p.cpf, '.', ''), '-', '')), p.email, p.name
    FROM advisement_authorizations aa, professors p
    WHERE aa.professor_id = p.id
    ORDER BY p.name
  SQL

  ACCREDITED_PROFESSORS_NEW = <<~SQL
    SELECT DISTINCT CONCAT('1', REPLACE(REPLACE(p.cpf, '.', ''), '-', '')), p.email, p.name
    FROM advisement_authorizations aa, professors p
    WHERE aa.professor_id = p.id
    AND DATE(aa.start_date) <= CURRENT_DATE
    AND (aa.end_date IS NULL OR DATE(aa.end_date) >= CURRENT_DATE)
    ORDER BY p.name
  SQL

  def up
    rewrite(STUDENTS_PER_PROFESSOR,
      from: [STUDENTS_PER_PROFESSOR_OLD], to: STUDENTS_PER_PROFESSOR_NEW)
    rewrite(ACCREDITED_PROFESSORS,
      from: [ACCREDITED_PROFESSORS_OLD, ACCREDITED_PROFESSORS_OLD_DOUBLE_QUOTES],
      to: ACCREDITED_PROFESSORS_NEW)
  end

  def down
    rewrite(STUDENTS_PER_PROFESSOR,
      from: [STUDENTS_PER_PROFESSOR_NEW], to: STUDENTS_PER_PROFESSOR_OLD)
    rewrite(ACCREDITED_PROFESSORS,
      from: [ACCREDITED_PROFESSORS_NEW], to: ACCREDITED_PROFESSORS_OLD)
  end

  private
    def rewrite(name, from:, to:)
      known = from.map { |sql| normalize(sql) }
      Query.where(name: name).find_each do |query|
        if known.include?(normalize(query.sql))
          query.update_column(:sql, to)
        else
          say "Consulta ##{query.id} (#{query.name}) foi personalizada: " \
            "revise o filtro de vigência do credenciamento à mão"
        end
      end
    end

    # A tela grava quebra de linha como CRLF, e os seeds até 7.15.23 também.
    def normalize(sql)
      sql.to_s.gsub("\r\n", "\n").strip
    end
end
