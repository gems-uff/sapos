# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

Phase.create([
  { name: "Pedido de Banca", is_language: false },
  { name: "Exame de Qualificação", is_language: false },
  { name: "Artigo A1/A2/B1", is_language: false },
  { name: "Prova de Inglês", is_language: true },
])

PhaseDuration.create([
  { level_name: "Doutorado", phase_name: "Pedido de Banca", deadline_semesters: 8, deadline_months: 0, deadline_days: 0 },
  { level_name: "Mestrado", phase_name: "Pedido de Banca", deadline_semesters: 4, deadline_months: 0, deadline_days: 0 },
  { level_name: "Doutorado", phase_name: "Exame de Qualificação", deadline_semesters: 5, deadline_months: 0, deadline_days: 0 },
  { level_name: "Doutorado", phase_name: "Prova de Inglês", deadline_semesters: 1, deadline_months: 0, deadline_days: 0 },
  { level_name: "Mestrado", phase_name: "Prova de Inglês", deadline_semesters: 1, deadline_months: 0, deadline_days: 0 },
  { level_name: "Doutorado", phase_name: "Artigo A1/A2/B1", deadline_semesters: 8, deadline_months: 0, deadline_days: 0 },
].map do |phase_duration|
  phase_duration.except(:level_name, :phase_name).merge({
    level: Level.find_by_name(phase_duration[:level_name]),
    phase: Phase.find_by_name(phase_duration[:phase_name])
  })
end)


DeferralType.create([
  { name: "Prorrogação de EQ", duration_semesters: 1, duration_months: 0, duration_days: 0, phase_name: "Exame de Qualificação" },
  { name: "Prorrogação Regular", duration_semesters: 1, duration_months: 0, duration_days: 0, phase_name: "Pedido de Banca" },
  { name: "Prorrogação Final", duration_semesters: 0, duration_months: 3, duration_days: 0, phase_name: "Pedido de Banca" },
  { name: "Prorrogação Extraordinária", duration_semesters: 1, duration_months: 0, duration_days: 0, phase_name: "Pedido de Banca" },
  { name: "Trancamento de Matrícula", duration_semesters: 1, duration_months: 0, duration_days: 0, phase_name: "Pedido de Banca" },
  { name: "Segunda Chamada Prova de Inglês", duration_semesters: 1, duration_months: 0, duration_days: 0, phase_name: "Prova de Inglês" },
].map do |deferral_type|
  deferral_type.except(:phase_name).merge({
    phase: Phase.find_by_name(deferral_type[:phase_name])
  })
end)

